//
//  GADAdLoaderAdTypes.h
//  Google Mobile Ads SDK
//
//  Copyright 2015 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GoogleMobileAds/GoogleMobileAdsDefines.h>

GAD_ASSUME_NONNULL_BEGIN

/// Use with GADAdLoader to request native app install ads. To receive ads, the ad loader's delegate
/// must conform to the GADNativeAppInstallAdRequestDelegate protocol. See GADNativeAppInstallAd.h.
///
/// See GADNativeAdImageAdLoaderOptions.h for ad loader image options.
GAD_EXTERN NSString *const kGADAdLoaderAdTypeNativeAppInstall;

/// Use with GADAdLoader to request native content ads. To receive ads, the ad loader's delegate
/// must conform to the GADNativeContentAdRequestDelegate protocol. See GADNativeContentAd.h.
///
/// See GADNativeAdImageAdLoaderOptions.h for ad loader image options.
GAD_EXTERN NSString *const kGADAdLoaderAdTypeNativeContent;

/// Use with GADAdLoader to request native custom template ads. To receive ads, the ad loader's
/// delegate must conform to the GADNativeCustomTemplateAdLoaderDelegate protocol. See
/// GADNativeCustomTemplateAd.h.
GAD_EXTERN NSString *const kGADAdLoaderAdTypeNativeCustomTemplate;

GAD_ASSUME_NONNULL_END
