/* Copyright 2017 Urban Airship and Contributors */

#import "UAOpenExternalURLAction.h"

#define kUAWalletActionDefaultRegistryName @"wallet_action"
#define kUAWalletActionDefaultRegistryAlias @"^w"

/**
 * Opens a wallet URL, either in safari or using custom URL schemes. This action is
 * registered under the names ^w and wallet_action.
 *
 * Expected argument values: NSString
 *
 * Valid situations: UASituationForegroundPush, UASituationLaunchedFromPush
 * UASituationWebViewInvocation, UASituationForegroundInteractiveButton,
 * UASituationManualInvocation, and UASituationAutomation
 *
 * Result value: An NSString representation of the input
 *
 * Error: `UAOpenExternalURLActionErrorCodeURLFailedToOpen` if the URL could not be opened
 *
 * Fetch result: UAActionFetchResultNoData
 */
@interface UAWalletAction : UAOpenExternalURLAction


@end
