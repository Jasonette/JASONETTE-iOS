//
//  JasonWebsocketAction.m
//  Jasonette
//
//  Created by e on 11/3/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonWebsocketAction.h"

@implementation JasonWebsocketAction

/*****************************************
 
 ### Actions:
 - There are 3 actions: Open, Close, Send
 - All actions are asynchronous => They don't wait for a response and immediately calls "success"
 - Instead of a return value, all of these actions trigger a service.
 - The corresponding service (can be seen at JasonWebsocketService) emits an event when there's a result.
 
 [1] Open
 {
     "type": "$websocket.open",
     "options": {
         "url": "..."
     },
     "success": { ... }
 }
 
 [2] Close
 {
    "type": "$websocket.close",
    "success": { ... }
 }
 
 [3] Send
 {
     "type": "$websocket.send",
     "options": {
         "message": "..."
     },
     "success": { ... }
 }

 *****************************************/

- (void) open {
    JasonWebsocketService *service = [Jason client].services[@"JasonWebsocketService"];
    [service open: self.options];
    [[Jason client] success];
}
- (void) close {
    JasonWebsocketService *service = [Jason client].services[@"JasonWebsocketService"];
    [service close];
    [[Jason client] success];
}
- (void) send {
     JasonWebsocketService *service = [Jason client].services[@"JasonWebsocketService"];
     [service send: self.options];
     [[Jason client] success];
}
@end
