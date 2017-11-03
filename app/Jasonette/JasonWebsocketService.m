//
//  JasonWebsocketService.m
//  Jasonette
//
//  Created by e on 11/3/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonWebsocketService.h"

@implementation JasonWebsocketService

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
    [self.websocket close];
}
- (void) send: (NSDictionary *) options {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self.websocket send: options[@"text"]];
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
            @"message": [error description]
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
