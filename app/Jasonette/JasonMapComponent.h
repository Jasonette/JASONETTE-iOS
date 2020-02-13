//
//  JasonMapComponent.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonComponent.h"
#import <MapKit/MapKit.h>
#import "NSObject+JSONPayload.h"

@interface JasonMapComponent : JasonComponent <MKMapViewDelegate>
+ (void)setRegion:(MKMapView *)mapView;
@end
