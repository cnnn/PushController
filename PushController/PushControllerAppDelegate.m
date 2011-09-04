//
//  PushControllerAppDelegate.m
//  PushController
//
//  Created by Ishaan Gandhi on 8/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PushControllerAppDelegate.h"
#import <Security/Security.h>

@implementation PushControllerAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    server = [[HTTPServer alloc] init];
    [server setDelegate:self];
    NSError *err = nil;
    [server start:&err];
    
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    
    if(err) {
        NSLog(@"Server failed to start %@", err);
        return;
    }
    registeredUsers = [[NSMutableArray alloc] init];
    service = [[NSNetService alloc] initWithDomain:@"" 
                                              type:@"_http._tcp." 
                                              name:@"CocoaHTTPServer" 
                                              port:[server port]];
    [service setDelegate:self];
    [service publish];
    
    [self connectToNotificationServer];
}

-(void)netServiceDidPublish:(NSNetService *)sender {
    [status setStringValue:@"Server is advertising"];
}

-(void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict{
    [status setStringValue:@"Server is not advertising"];
}

-(void)netServiceDidStop:(NSNetService *)sender {
    [status setStringValue:@"Server is not advertising"];
}

- (void)HTTPConnection:(HTTPConnection *)conn
     didReceiveRequest:(HTTPServerRequest *)mess
{
    BOOL requestWasOkay = NO;
    
    CFHTTPMessageRef request = [mess request];
    
    NSString *method = [(NSString *)CFHTTPMessageCopyRequestMethod(request)
                        autorelease];
    
    if ([method isEqualToString:@"POST"]) {
        NSURL *requestURL = [(NSURL *)CFHTTPMessageCopyRequestURL(request)
                             autorelease];
        
       // if ([[requestURL absoluteString] isEqualToString:@"/register"]) {
            requestWasOkay = [self handleRegister:request];
        //}
    }
    
    CFHTTPMessageRef response = NULL;
    if (requestWasOkay) {
        response = CFHTTPMessageCreateResponse(NULL, 
                                               200, 
                                               NULL, 
                                               kCFHTTPVersion1_1);
    } else {
        response = CFHTTPMessageCreateResponse(NULL, 
                                               400, 
                                               NULL, 
                                               kCFHTTPVersion1_1);    
    }
    
    CFHTTPMessageSetHeaderFieldValue(response, 
                                     (CFStringRef)@"Content-Length", 
                                     (CFStringRef)@"0");
    
    [mess setResponse:response];
    
    CFRelease(response);
}

-(void)connectToNotificationServer {
    CFStreamCreatePairWithSocketToHost(NULL,
                                       (CFStringRef)@"gateway.sandbox.push.apple.com",
                                       2195, 
                                       (CFReadStreamRef *)(&readStream), 
                                       (CFWriteStreamRef *)(&writeStream));
    
    [readStream open];
    [writeStream open];
    
    if ([readStream streamStatus] != NSStreamStatusError
    && [writeStream streamStatus] != NSStreamStatusError){
        [self configureStreams];
    }   else {
        NSLog(@"Failed to connect to Apple.");
    }
}

-(BOOL)handleRegister:(CFHTTPMessageRef)request {
    NSData *body = [(NSData *)CFHTTPMessageCopyBody(request) autorelease];
    NSDictionary *bodyDict = [NSPropertyListSerialization propertyListFromData:body mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
    
    NSData *token = [bodyDict objectForKey:@"token"];
    NSString *name = [bodyDict objectForKey:@"name"];
    
    NSLog(@"%@, %@", name, token);
    if(name && token) {
        BOOL unique = YES;
        for(NSDictionary *d in registeredUsers) {
            if ([[d objectForKey:@"token"] isEqual:token]) {
                unique = NO;
            }
        }
        if(unique) {
            [registeredUsers addObject:bodyDict];
            [tableView reloadData];
        }
        return YES;
    }
    return NO;
}

-(NSArray *)certificateArray
{
    NSString *certPath = 
    [[NSBundle mainBundle] pathForResource:@"aps_developer_identity" 
                                    ofType:@"cer"];
    
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    SecCertificateRef cert = SecCertificateCreateWithData(NULL, (CFDataRef)certData);
    
    // Create the identity (private key) which requires
    // that the certificate lives in the keychain
    SecIdentityRef identity;
    OSStatus err = SecIdentityCreateWithCertificate(NULL, cert, &identity);
    if(err) {
        NSLog(@"Failed to create certificate identity: %d", err);
        return nil;
    }
    
    return [NSArray arrayWithObjects:(id)identity, (id)cert, nil];
}

- (NSData *)notificationDataForMessage:(NSString *)msgText token:(NSData *)token 
{    
    
    // To signify the enhanced format, we use 1 as the first byte 
    uint8_t command = 1;
    
    // This is the identifier for this specific notification 
    static uint32_t identifier = 5000;
    
    // The notification will expire in one day 
    uint32_t expiry = htonl(time(NULL) + 86400);
    
    // Find the binary lengths of the data we will send 
    uint16_t tokenLength = htons([token length]);
    
    // Must escape text before inserting in JSON
    NSMutableString *escapedText = [[msgText mutableCopy] autorelease];
    
    /* Replace \ with \\ */
    [escapedText replaceOccurrencesOfString:@"\\"
                                 withString:@"\\\\"
                                    options:0
                                      range:NSMakeRange(0, [escapedText length])];
    
    // Replace " with \"
    [escapedText replaceOccurrencesOfString:@"\"" 
                                 withString:@"\\\"" 
                                    options:0 
                                      range:NSMakeRange(0, [escapedText length])];
    
    // Construct the JSON payload to deliver to the device
    NSString *payload = [NSString stringWithFormat:
                         @"{\"aps\":{\"alert\":\"%@\",\"sound\":\"CrackSoundEffect.aif\",\"badge\":1}}", 
                         escapedText];
    
    // We'll have to encode this into a binary buffer, so NSString won't fly 
    const char *payloadBuffer = [payload UTF8String];
    
    // Note: sending length to an NSString will give us the number 
    // of characters, not the number of bytes, but strlen 
    // gives us the number of bytes. (Some characters 
    // take up more than one byte in Unicode)
    uint16_t payloadLength = htons(strlen(payloadBuffer));
    
    // Create a binary data container to pack all of the data 
    NSMutableData *data = [NSMutableData data];
    
    // Add each component in the right order to the data container
    [data appendBytes:&command length:sizeof(uint8_t)];
    
    [data appendBytes:&identifier length:sizeof(uint32_t)];
    
    [data appendBytes:&expiry length:sizeof(uint32_t)];
    
    [data appendBytes:&tokenLength length:sizeof(uint16_t)];
    [data appendBytes:[token bytes] length:[token length]];
    
    [data appendBytes:&payloadLength length:sizeof(uint16_t)];
    [data appendBytes:payloadBuffer length:strlen(payloadBuffer)];
    
    // Increment the identifier for the next notification 
    identifier++;
    
    return data;
}

-(void)configureStreams {
    NSArray *certArray = [self certificateArray];
    if(!certArray) 
        return;
    
    NSDictionary *sslSettings =
    [NSDictionary dictionaryWithObjectsAndKeys:[self certificateArray],
     (id)kCFStreamSSLCertificates,
     (id)kCFStreamSocketSecurityLevelNegotiatedSSL,
     (id)kCFStreamSSLLevel, nil];
    
    [writeStream setProperty:sslSettings forKey:(id)kCFStreamPropertySSLSettings];
    [readStream setProperty:sslSettings forKey:(id)kCFStreamPropertySSLSettings];
    
    [readStream setDelegate:self];
    [writeStream setDelegate:self];
    
    [writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

}

- (IBAction)pushMessage:(id)sender
{    
    NSInteger row = [tableView selectedRow];
    if (row == -1)
        return;
    NSString *msgText = [messageField stringValue];
    NSData *token = [[registeredUsers objectAtIndex:row] objectForKey:@"token"];
    
    NSData *data = [self notificationDataForMessage:msgText token:token];
    [writeStream write:[data bytes] maxLength:[data length]];
}
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode)
    {
        case NSStreamEventHasBytesAvailable:
        {
            if (aStream == readStream)
            {
                // If data came back from the server, we have an error
                // Let's fetch it out
                NSUInteger lengthRead = 0;
                do 
                {
                    // Error packet is always 6 bytes
                    uint8_t *buffer = malloc(6);
                    lengthRead = [readStream read:buffer maxLength:6];
                    
                    // First byte is command (always 8)
                    uint8_t command = buffer[0];
                    
                    // Second byte is the status code
                    uint8_t status = buffer[1];
                    
                    // This will be the notification identifier
                    uint32_t *ident = (uint32_t *)(buffer + 2);
                    
                    NSLog(@"ERROR WITH NOTIFICATION: %d %d %d", 
                          (int)command, (int)status, *ident);
                    
                    free(buffer);
                } while(lengthRead > 0);
            }
        } break;
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"%@ is open", aStream);
        } break;
        case NSStreamEventHasSpaceAvailable:
        {
            NSLog(@"%@ can accept bytes", aStream);
        } break;
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"%@ error: %@", aStream, [aStream streamError]);
        } break;
        case NSStreamEventEndEncountered:
        {
            NSLog(@"%@ ended - probably closed by server", aStream);
        } break;
    }
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *entry = [registeredUsers objectAtIndex:row];
    return [NSString stringWithFormat:@"%@ (%@)", [entry objectForKey:@"name"],
            [entry objectForKey:@"token"]];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [registeredUsers count];
}

@end