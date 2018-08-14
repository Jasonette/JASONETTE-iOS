//
//  JasonPushAction.m
//  Jasonette
//
//  Created by e on 8/21/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

/*
 
 
 ====================================
 
 ## Spec
 
 - actions
 - $push.register: sends device registration request to APNS
 - events
 - $push.onregister: Returns with device token as a result of $push.register
 - $push.onmessage: Handle push payload when foreground
 
 =================================
 
 ## Workflow
 
 ## Phase 1. Registration
 1. $push.register action => Registers this device to Apple for push notification
 2. Then Apple server returns a device token => this triggers "$push.onregister" event with $jason.token set as the newly assigned device token
 3. You need to store this token somewhere so you can use it later. In the following example we send it to our server. It will probably store the token under current user's database entry, so other users can send push notifications to this device through this user's device token.
 
 ## Phase 2. Sending push
 1. When sending a push notification, you make a POST request to APN/GCM server with metadata such as the destination token, message to display, and a JSON payload. The APN/GCM servers then sends push notifications to each device based on the device token.
 2. For the payload you should either pass a JASON action or href object. This will be used later when the receiver device handles the push notification.
 3. The sending can be done both from the client side and the server side (normally we use the server because that way we can keep a centralized database of all users' device tokens. Otherwise each device should have complete knowledge of all other users it wants to send push to).
 
 ## Phase 3. Receiving push
 When a user receives a push notification, the device could be either in the backgroud or foreground
 1. In case the app is in the background
 - it just displays the push notification on the lock screen.
 - when you open the notification from the lock screen, the "href" or "action" payload attached to the push notification gets executed. This way you can customize the behavior whichever way you want.
 2. In case the app is in the foreground
 - it triggers "$push.onmessage" event on the current view
 - if the current view doesn't have a "$push.onmessage" event defined under $jason.head.actions, nothing happens.
 - if the current view has a "$push.onmessage" event defined, the payload object gets passed in as "{{$jason}}". You can utilize this to do whatever you want but in most cases you probably want to use it as is to be consistent with the background behavior mentioned above
 
 ==========================
 
 # Examples
 
 ## Example 0. Registration
 
 To register a device token you need to call "$push.register" action.
 
 Then you need to handle the "$push.onregister" event which returns a device_token.
 
 {
    "$jason": {
        "head": {
            "title": "PUSH TEST",
            "actions": {
                "$load": {
                    "type": "$push.register"
                },
                "$push.onregister": {
                    "type": "$network.request",
                    "options": {
                        "url": "https://myserver.com/register_device.json",
                        "data": {
                            "token": "{{$jason.token}}"
                        }
                    }
                }
            }
        }
    }
 }
 
 
 
 
 ## Example 1. Handling Incoming push when the device is in background
 
 [A] Let's say, from phase 2, we're sending the following JSON payload to APNS:
 
 {
    "href": {
        "url": "https://news.ycombinator.com",
        "view": "web"
    }
 }
 
 When you open the notification, Jasonette would automatically detect the "href" object and run the href, resulting in a new browser that opens the link "https://news.ycombinator.com".
 
 [B] You can also include an "action" attribute to trigger an action instead of an "href":
 
 {
    "action": {
        "type": "$util.banner",
        "options": {
            "title": "Hello",
            "description": "World"
        }
    }
 }
 
 When you open the notification, Jasonette will automatically detect the "action" object and run the action, displaying a banner.
 
 
 
 ## Example 2. Handling incoming push when the device in foreground
 
 To handle push notifications when the app is in the foreground, you need to define a "$push.onmessage" event handler to the current view. Note that each view has its own "$push.onmessage" handler and can behave in their own ways. For example in a chat app, if you're in a chatroom, new chat messages should be appended, but if you're in the lobby where it displays a list of chatrooms, it should just display a "new" badge to the chatroom item which just received the new message.
 
 
 [A] Default payload handling
 
 Let's say, from phase 2, we're sending the following JSON payload to APNS:
 
 {
    "action": {
        "type": "$util.banner",
        "options": {
            "title": "Hello",
            "description": "World"
        }
    }
 }
 
 You will need to define the "$push.onmessage" handler in the view:
 
 {
    "$jason": {
        "head": {
            "title": "PUSH TEST",
            "actions": {
                "$push.onmessage": "{{$jason.action}}"
            }
        }
    }
 }
 
 This will run the "action" object from the push payload.
 
 [B] Using custom payload
 
 You don't need to use the "action" or "href" attributes, you can simply pass some custom attribute as a payload from the server:
 
 {
    "href": {
        "url": "https://news.ycombinator.com",
        "view": "web"
    },
    "some_custom_attribute": {
        "text": "Hello world"
    }
 }
 
 
 And in your view you can access the "custom" attribute simply by accessing "{{$jason.custom}}"
 
 {
    "$jason": {
        "head": {
            "title": "PUSH TEST",
            "actions": {
                "$push.onmessage": {
                    "type": "$util.toast",
                    "options": {
                        "text": "{{$jason.some_custom_attribute.text}}"
                    }
                }
            }
        }
    }
 }
 
 
 */




#import "JasonPushAction.h"
#define SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation JasonPushAction


- (void)register{
    // currently only remote notification
#ifdef PUSH
    if(SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(@"10.0")) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        JasonPushService *service = [Jason client].services[@"JasonPushService"];
        if(service) {
            center.delegate = service;
        }
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error){
            if( !error && granted){
                [[UIApplication sharedApplication] registerForRemoteNotifications];
                [[Jason client] success];
                
            } else {
                [[Jason client] error];
            }
        }];
    }
    else {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        [[Jason client] success];
    }
#else
    NSLog(@"Push notification turned off by default. If you'd like to suport push, uncomment the #define statement in Constants.h and turn on the push notification feature from the capabilities tab.");
#endif
    
}


@end

