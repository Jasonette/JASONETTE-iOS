//
//  JasonWebsocketService.m
//  Jasonette
//
//  Created by e on 11/3/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonWebsocketService.h"

@implementation JasonWebsocketService

/*****************************************
 
 ### Events:
 - There are 4 events: $websocket.onopen, $websocket.onclose, $websocket.onmessage, $websocket.onerror
 
 [1] $websocket.onopen
    - Triggered when $websocket.open action succeeds.
    - You can start sending messages after this event.
    - Response Payload: none
 
 [2] $websocket.onclose
    - Triggered when $websocket.close action succeeds or the socket closes
    - Response Payload: none
 
 [3] $websocket.onerror
    - Triggered when there's an error
    - Response Payload:
     {
         "$jason": {
             "error": [THE ERROR MESSAGE]
         }
     }

 [4] $websocket.onmessage
    - Triggered whenever there's an incoming message
    - Response Payload:
     {
         "$jason": {
             "message": [THE INCOMING MESSAGE STRING]
         }
     }
 
 *****************************************/


- (void) initialize: (NSDictionary *)launchOptions {
}

- (void) open: (NSDictionary *) options {
    // close if already open
    self.websocket.delegate = nil;
    [self.websocket close];
    
    self.websocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:options[@"url"]]];
    self.websocket.delegate = self;
    [self.websocket open];
}
- (void) close {
    self.websocket.delegate = nil;
    [self.websocket close];
}
- (void) send: (NSDictionary *) options {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self.websocket send: options[@"message"]];
    });
}

// $websocket.onopen
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSDictionary *events = [[[Jason client] getVC] valueForKey:@"events"];
    [[Jason client] call: events[@"$websocket.onopen"] with: @{}];
}


// $websocket.onerror
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSDictionary *events = [[[Jason client] getVC] valueForKey:@"events"];
    [[Jason client] call: events[@"$websocket.onerror"] with: @{
        @"$jason": @{
            @"error": [error description]
        }
    }];
}

// $websocket.onclose
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(nullable NSString *)reason wasClean:(BOOL)wasClean {
    NSDictionary *events = [[[Jason client] getVC] valueForKey:@"events"];
    [[Jason client] call: events[@"$websocket.onclose"]];
}


// $websocket.onmessage
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSDictionary *events = [[[Jason client] getVC] valueForKey:@"events"];
    [[Jason client] call: events[@"$websocket.onmessage"] with: @{
        @"$jason": @{
            @"message": message,
            @"type": @"string"
        }
    }];

}


@end
