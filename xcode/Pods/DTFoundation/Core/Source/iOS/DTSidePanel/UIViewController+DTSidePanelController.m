//
//  UIViewController+DTSidePanelController.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 5/24/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "UIViewController+DTSidePanelController.h"
#import <objc/runtime.h>
#import "DTSidePanelController.h"

static char DTSidePanelControllerKey;

@implementation UIViewController (DTSidePanelController)

- (DTSidePanelController *)sidePanelController
{
	DTSidePanelController *controller = objc_getAssociatedObject(self, &DTSidePanelControllerKey);
	
	if (controller)
	{
		return controller;
	}
	
	// try the parent
	if (self.parentViewController)
	{
		return [self.parentViewController sidePanelController];
	}
	
	return nil;
}

- (void)setSidePanelController:(DTSidePanelController *)sidePanelController
{
	return objc_setAssociatedObject(self, &DTSidePanelControllerKey, sidePanelController, OBJC_ASSOCIATION_ASSIGN);
}

@end
