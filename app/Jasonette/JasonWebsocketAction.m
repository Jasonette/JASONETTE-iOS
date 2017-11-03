//
//  JasonWebsocketAction.m
//  Jasonette
//
//  Created by e on 11/3/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonWebsocketAction.h"

@implementation JasonWebsocketAction

/*
 {
     "type": "$websocket.open",
     "options": {
         "url": "..."
     }
 }
 */
- (void) open {
    JasonWebsocketService *service = [Jason client].services[@"JasonWebsocketService"];
    [service open: self.options];
    [[Jason client] success];
}

/*
 {
     "type": "$websocket.close"
 }
 */
- (void) close {
    JasonWebsocketService *service = [Jason client].services[@"JasonWebsocketService"];
    [service close];
    [[Jason client] success];
}

/*
 {
     "type": "$websocket.send",
     "options": {
        "type": "raw",
        "text": "..."
     }
 }

 {
     "type": "$websocket.send",
     "options": {
         "type": "string",
         "text": "..."
     }
 }
*/
 - (void) send {
     JasonWebsocketService *service = [Jason client].services[@"JasonWebsocketService"];
     [service send: self.options];
     [[Jason client] success];
}
@end
