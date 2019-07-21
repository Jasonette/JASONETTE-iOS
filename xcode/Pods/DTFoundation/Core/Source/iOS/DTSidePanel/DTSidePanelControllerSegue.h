//
//  DTSidePanelControllerSeque.h
//  DTFoundation
//
//  Created by René Swoboda on 09/07/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <DTFoundation/DTWeakSupport.h>

@class DTSidePanelController;

/**
 A segue for setting the DTSidePanelController panel ViewController via storyboard.
 */
@interface DTSidePanelControllerSegue : UIStoryboardSegue

/**
 The DTSidePanelController for the segue.
 */
@property (DT_WEAK_PROPERTY, nonatomic) DTSidePanelController *sidePanelController;

/**
 Returns the position of the sidepanel from the storyboard segue identifier. POSITION(OPTION) e.g.: DTSidePanelCenter(showSettings)
 @param identifier the segue identifier
 @return the position of the sidepanel (DTSidePanelLeft, DTSidePanelCenter, DTSidePanelRight, DTSidePanelNone)
 */
+ (NSString *) getPositionIdentifier:(NSString *)identifier;

/**
 Returns the option for the sidepanel from the storyboard segue identifier. The option can be used to identify the segue in your ViewController and wont be used by the DTSidePanelController. POSITION(OPTION) e.g.: DTSidePanelCenter(showSettings)
 @param identifier the segue identifier
 @return the option from the segue
 */
+ (NSString *) getOptionIdentifier:(NSString *)identifier;

@end