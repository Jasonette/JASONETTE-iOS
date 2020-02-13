//
//  JasonNotificationAction.m
//  Jasonette
//
//  Created by Unknower on 11/6/16.
//  Copyright © 2016 Jasonette. All rights reserved.
//

#import "JasonNotificationAction.h"

@implementation JasonNotificationAction

- (void)register{
    // currently only remote notification
    
    /* Example Syntax related to remote notifications
     
     1. $notification.register action => Registers this device to Apple for push notification
     2. Then Apple server returns a device token => this triggers "$notification.registered" event with $jason.device_token set as the newly assigned device token
     3. You can use this value to do whatever you want. In the following example we send it to our server. It will probably store the device_token under current user's database entry
     4. Also, when the user receives a push notification while the app is in the foreground, it triggers "$notification.remote" event. In this case the entire push payload will be stored inside $jason. you can utilize this value to run any other action. In this case we call a $util.banner.

     {
         "$jason": {
            "head": {
                "title": "PUSH TEST",
                "actions": {
                    "$load": {
                        "type": "$notification.register"
                    },
                    "$notification.registered": {
                        "type": "$network.request",
                        "options": {
                            "url": "https://myserver.com/register_device.json",
                            "data": {
                                "device_token": "{{$jason.device_token}}"
                            }
                        }
                    },
                    "$notification.remote": {
                        "type": "$util.banner",
                        "options": {
                            "title": "Message",
                            "description": "{{JSON.stringify($jason)}}"
                        }
                    }
                }
            }
         }
     }

     
     */
    
    
    // Todo: Local Notification maybe?
    // {
    //      "type": "$notification.register",
    //      "options": {
    //          "type": "local"
    //      }
    // }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"registerNotification" object:nil];

    [[Jason client] success];
}



@end
