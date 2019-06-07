//
//  JasonWebsocketService.h
//  Jasonette
//
//  Created by e on 11/3/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SocketRocket.h>
#import "Jason.h"

@interface JasonWebsocketService : NSObject <SRWebSocketDelegate>
@property (nonatomic, strong) SRWebSocket *websocket;
- (void) open: (NSDictionary *)options;
- (void) close;
- (void) send: (NSDictionary *)options;
@end
