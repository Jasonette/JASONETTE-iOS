//
//  VALSinglePromptSecureEnclaveValet.h
//  Valet
//
//  Created by Dan Federman on 1/23/17.
//  Copyright © 2017 Square, Inc. All rights reserved.
//

#import <Valet/VALSecureEnclaveValet.h>


/// Reads and writes keychain elements that are stored on the Secure Enclave (available on iOS 8.0 and later and macOS 10.11 and later) using accessibility attribute VALAccessibilityWhenPasscodeSetThisDeviceOnly. The first access of these keychain elements will require the user to confirm their presence via Touch ID or passcode entry.
/// @see VALSecureEnclaveValet
/// @version Available on iOS 8 or later, and macOS 10.11 or later.
@interface VALSinglePromptSecureEnclaveValet : VALSecureEnclaveValet

/// Forces a prompt for Touch ID or passcode entry on the next data retrieval from the Secure Enclave.
- (void)requirePromptOnNextAccess;

@end
