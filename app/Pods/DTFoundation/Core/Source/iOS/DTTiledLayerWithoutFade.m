//
//  DTTiledLayerWithoutFade.m
//  DTRichTextEditor
//
//  Created by Oliver Drobnik on 8/24/11.
//  Copyright 2011 Cocoanetics. All rights reserved.
//

#import "DTTiledLayerWithoutFade.h"

@implementation DTTiledLayerWithoutFade

+ (CFTimeInterval)fadeDuration
{
	return 0;
}

+ (BOOL)shouldDrawOnMainThread
{
    return YES;
}

@end
