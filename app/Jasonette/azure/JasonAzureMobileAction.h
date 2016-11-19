//
//  JasonAzureAction.h
//  Jasonette
//
//  Copyright © 2016 seletz. All rights reserved.
//

// Azure Notification Hub
#import <MicrosoftAzureMobile/MicrosoftAzureMobile.h>

#import "JasonAction.h"
@interface JasonAzuremobileAction : JasonAction {
    MSClient *client;
}


@property (nonatomic, retain) MSClient *client;

+ (id)sharedInstance;

@end
