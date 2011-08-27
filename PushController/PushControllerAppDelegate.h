//
//  PushControllerAppDelegate.h
//  PushController
//
//  Created by Ishaan Gandhi on 8/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Security/Security.h>
#import "HTTPServer.h"

@interface PushControllerAppDelegate : NSObject 
<NSApplicationDelegate, NSTableViewDelegate,
    NSTableViewDataSource, NSNetServiceDelegate,
    NSStreamDelegate> {
    NSWindow *window;
    
    IBOutlet NSTableView *tableView;
    IBOutlet NSTextField *status;
    
    IBOutlet NSTextField *messageField;
    
    NSOutputStream *writeStream;
    NSOutputStream *readStream;
        
    NSNetService *service;
    
    NSMutableArray *registeredUsers;
        
        HTTPServer *server;
}

@property (assign) IBOutlet NSWindow *window;

-(BOOL)handleRegister:(CFHTTPMessageRef)request;
-(void)configureStreams;
-(void)connectToNotificationServer;
- (NSData *)notificationDataForMessage:(NSString *)msgText token:(NSData *)token;
-(IBAction)pushMessage:(id)sender;


@end
