//
//  JasonGeoAction.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonGeoAction.h"

@implementation JasonGeoAction

- (void)get{
    INTULocationManager *locMgr = [INTULocationManager sharedInstance];
    [[Jason client] loading:YES];
    
    // distance accuracy
    INTULocationAccuracy accuracy = INTULocationAccuracyCity;
    if(self.options && self.options[@"distance"]){
        NSInteger distance = [self.options[@"distance"] integerValue];
        if(distance <= 5){
            accuracy = INTULocationAccuracyRoom;
        } else if(distance <= 15){
            accuracy = INTULocationAccuracyHouse;
        } else if(distance <= 100){
            accuracy = INTULocationAccuracyBlock;
        } else if(distance <= 1000){
            accuracy = INTULocationAccuracyNeighborhood;
        } else if(distance <= 5000){
            accuracy = INTULocationAccuracyCity;
        } else {
            accuracy = INTULocationAccuracyCity;
        }
    }
    
    [locMgr requestLocationWithDesiredAccuracy:accuracy
                                       timeout:10.0
                          delayUntilAuthorized:YES  // This parameter is optional, defaults to NO if omitted
                                         block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                             if (status == INTULocationStatusSuccess) {
                                                 // Request succeeded, meaning achievedAccuracy is at least the requested accuracy, and
                                                 // currentLocation contains the device's current location.
                                                 NSString *coord = [NSString stringWithFormat:@"%g,%g", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
                                                [[Jason client] success: @{@"coord": coord}];
                                             }
                                             else if (status == INTULocationStatusTimedOut) {
                                                 // Wasn't able to locate the user with the requested accuracy within the timeout interval.
                                                 // However, currentLocation contains the best location available (if any) as of right now,
                                                 // and achievedAccuracy has info on the accuracy/recency of the location in currentLocation.
                                                 NSString *coord = [NSString stringWithFormat:@"%g,%g", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
                                                [[Jason client] success: @{@"coord": coord}];
                                             }
                                             else {
                                                [[Jason client] error];
                                             }
                                         }];

}

@end
