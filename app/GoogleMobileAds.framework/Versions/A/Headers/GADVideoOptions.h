//
//  GADVideoOptions.h
//  Google Mobile Ads SDK
//
//  Copyright 2016 Google Inc. All rights reserved.
//

#import <GoogleMobileAds/GADAdLoader.h>
#import <GoogleMobileAds/GoogleMobileAdsDefines.h>

GAD_ASSUME_NONNULL_BEGIN

/// Video ad options.
@interface GADVideoOptions : GADAdLoaderOptions

/// Indicates if videos should start muted.
@property(nonatomic, assign) BOOL startMuted;

@end

GAD_ASSUME_NONNULL_END
