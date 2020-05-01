//
//  DTSidePanelControllerSeque.m
//  DTFoundation
//
//  Created by René Swoboda on 09/07/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTSidePanelControllerSegue.h"
#import "DTSidePanelController.h"


@implementation DTSidePanelControllerSegue

- (void)perform
{
    NSParameterAssert(_sidePanelController);
    
    NSString *positionIdentifier = [DTSidePanelControllerSegue getPositionIdentifier:self.identifier];
    DTSidePanelControllerPanel presentPanel = DTSidePanelControllerPanelNone;
    
    if ([_sidePanelController.leftPanelController isEqual:self.destinationViewController])
    {
        presentPanel = DTSidePanelControllerPanelLeft;
    }
    else if ([_sidePanelController.centerPanelController isEqual:self.destinationViewController])
    {
        presentPanel = DTSidePanelControllerPanelCenter;
    }
    else if ([_sidePanelController.rightPanelController isEqual:self.destinationViewController])
    {
        presentPanel = DTSidePanelControllerPanelRight;
    }
    else if ([positionIdentifier isEqualToString:DTSidePanelModalIdentifier])
    {
        [_sidePanelController presentViewController:self.destinationViewController animated:YES completion:nil];

        return;
    }
    else if ([positionIdentifier isEqualToString:DTSidePanelLeftIdentifier])
    {
        // If there is no other view controller don't present the controller.
        if (_sidePanelController.centerPanelController != nil)
        {
            presentPanel = DTSidePanelControllerPanelLeft;
        }
        
        [_sidePanelController setLeftPanelController:self.destinationViewController];
    }
    else if ([positionIdentifier isEqualToString:DTSidePanelCenterIdentifier])
    {
        // If there is no other view controller don't present the controller.
        if (_sidePanelController.centerPanelController != nil)
        {
            presentPanel = DTSidePanelControllerPanelCenter;
        }
        
        [_sidePanelController setCenterPanelController:self.destinationViewController];
    }
    else if ([positionIdentifier isEqualToString:DTSidePanelRightIdentifier])
    {
        // If there is no other view controller don't present the controller.
        if (_sidePanelController.centerPanelController != nil)
        {
            presentPanel = DTSidePanelControllerPanelRight;
        }
        
        [_sidePanelController setRightPanelController:self.destinationViewController];
    }
    
    if (presentPanel != DTSidePanelControllerPanelNone)
    {
        [_sidePanelController presentPanel:presentPanel animated:YES];
    }
}

+ (NSString *) getPositionIdentifier:(NSString *)identifier{
    // If aditional options are present within the identifier extract the position identifier.
    if([identifier rangeOfString:@"("].location != NSNotFound)
    {
        [identifier stringByReplacingOccurrencesOfString:@")" withString:@""];
        
        NSArray *tmpArray = [identifier componentsSeparatedByString:@"("];
        
        return [tmpArray objectAtIndex:0];
    }
    
    return identifier;
}

+ (NSString *) getOptionIdentifier:(NSString *)identifier{
    // If aditional options are present within the identifier extract the position identifier.
    if([identifier rangeOfString:@"("].location != NSNotFound)
    {
        [identifier stringByReplacingOccurrencesOfString:@")" withString:@""];
        
        NSArray *tmpArray = [identifier componentsSeparatedByString:@"("];
        
        return [tmpArray objectAtIndex:1];
    }
    
    return nil;
}

@end