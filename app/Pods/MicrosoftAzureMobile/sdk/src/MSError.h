// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#ifndef MicrosoftAzureMobile_MSError_h
#define MicrosoftAzureMobile_MSError_h

#import <Foundation/Foundation.h>

#pragma mark * MSErrorDomain


/// The error domain for the Microsoft Azure Mobile Service client framework
extern NSString *const MSErrorDomain;


#pragma mark * UserInfo Request and Response Keys


/// The key to use with the *NSError* userInfo dictionary to retrieve the request
/// that was sent to the Microsoft Azure Mobile Service related to the error. Not
/// all errors will include the request so the userInfo dicitionary may return
/// nil.
extern NSString *const MSErrorRequestKey;

/// The key to use with the *NSError* userInfo dictionary to retrieve the
/// response that was returned from the Microsoft Azure Mobile Service related to
/// the error. Not all errors will include the response so the userInfo
/// dicitionary may return nil.
extern NSString *const MSErrorResponseKey;

/// The key to use with the *NSError* userInfo dictionary to retrieve the
/// server item that was returned from the Microsoft Azure Mobile Service related to
/// the precondition failed error. This will only be present on MSPreconditionFailed
/// errors.
extern NSString *const MSErrorServerItemKey;

/// The key to use with the *NSError* userInfo dictionary to retrieve the
/// *MSPushCompletionResult* object of accumalted operation errors when a push
/// was attempted
extern NSString *const MSErrorPushResultKey;


#pragma mark * MSErrorCodes


/// Indicates that a request to the Microsoft Azure Mobile Service failed because
/// a nil item was used.
#define MSExpectedItemWithRequest               -1101

/// Indicates that a request to the Microsoft Azure Mobile Service failed because
/// an item without an id was used
#define MSMissingItemIdWithRequest              -1102

/// Indicates that a request to the Microsoft Azure Mobile Service failed because
/// an invalid item was used.
#define MSInvalidItemWithRequest                -1103

/// Indicates that a request to the Microsoft Azure Mobile Service failed because
/// a nil itemId was used.
#define MSExpectedItemIdWithRequest             -1104

/// Indicates that a request to the Microsoft Azure Mobile Service failed because
/// an invalid itemId was used.
#define MSInvalidItemIdWithRequest              -1105

/// Indicates that a request to the Microsoft Azure Mobile Service failed because
/// an invalid user-parameter in the query string.
#define MSInvalidUserParameterWithRequest       -1106

/// Indicates that a request to the Microsoft Azure Mobile Service failed because
/// an item with an id was used with an insert operation.
#define MSExistingItemIdWithRequest             -1107

/// Indicates that a request to the Microsoft Azure Mobile Service failed because
/// the request was to a version that did not support the requested feature
#define MSInvalidBackendVersion                 -1108

/// Indicates that a sync table request failed because an invalid operation was
/// requested. This can occur due to operations on the same item that can not be
/// reconciled, such as two inserts on the same record
#define MSSyncTableInvalidAction                -1150

/// Indicates a sync table operation failed because the datasource returned an
/// error when attempting to read or write to it
#define MSSyncTableLocalStoreError              -1153

/// Indicates a sync table operation failed due to an internal error
#define MSSyncTableInternalError                -1154

/// Indicates that the query key contains invalid characters
#define MSInvalidQueryId                        -1155

/// Indicates a sync table operation could not be canceled
#define MSSyncTableCancelError                  -1156

/// Indicates a sync table operation could not be updated/removed as it no longer exists
#define MSSyncTableOperationNotFound            -1157

/// Indicates a mobile service sync operation (such as a syncTable insert) failed
/// because the sync context object was not properly initialized
#define MSSyncContextInvalid                    -1160

/// Indicates that the push completed sending all operation to the server but not
/// all table operations completed successfully. An array of the errors that
/// resulted can be found using the MSErrorPushResultKey
#define MSPushCompleteWithErrors                -1170

/// Indicates that the push was aborted (not all pending operations were sent to
/// the server) because the data source returned an error. The error causing the
/// abort can be found using the NSUnderlyingErrorKey
#define MSPushAbortedDataSource                 -1171

/// Indicates that the push was aborted (not all pending operations were sent to
/// the server) because of a network related issue, such as the mobile service
/// was not found. The error causing the abort can be found using the
/// NSUnderlyingErrorKey
#define MSPushAbortedNetwork                    -1172

/// Indicates that the push was aborted (not all pending operations were sent to
/// the server) because authentication was required to complete an operation.
/// The error causing the abort can be found using the NSUnderlyingErrorKey
#define MSPushAbortedAuthentication             -1173

/// Indicates that the push was aborted (not all pending operations were sent to
/// the server) for an unknown reason. The error causing the abort can be found
/// using the NSUnderlyingErrorKey
#define MSPushAbortedUnknown                    -1174

/// Indicates that the purge was aborted because items in the requested table to
/// purge have pending changes that need to be pushed to the server
#define MSPurgeAbortedPendingChanges            -1180

/// Indicates that the pull was aborted (not all records were retrieved from the
/// server) for an unknown reason.
#define MSPullAbortedUnknown                    -1190

/// Indicates that the response from the Microsoft Azure Mobile App did not
/// include an item as expected.
#define MSExpectedItemWithResponse              -1201

/// Indicates that the response from the Microsoft Azure Mobile App did not
/// include an array of items as expected.
#define MSExpectedItemsWithResponse             -1202

/// Indicates that the response from the Microsoft Azure Mobile App did not
/// include a total count as expected.
#define MSExpectedTotalCountWithResponse        -1203

/// Indicates that the response from the Microsoft Azure Mobile App did not
/// have body content as expected.
#define MSExpectedBodyWithResponse              -1204

/// Indicates that the response from the Microsoft Azure Mobile App indicated
/// there was an error but that an error message was not provided.
#define MSErrorNoMessageErrorCode               -1301

/// Indicates that the response from the Microsoft Azure Mobile App indicated
/// there was an error and an error message was provided.
#define MSErrorMessageErrorCode                 -1302

/// Indicates that the response from the Microsoft Azure Mobile App indicated
/// there was an error
#define MSErrorPreconditionFailed               -1303

/// Indicates that a request to the Microsoft Azure Mobile App failed because
/// the *NSPredicate* used in the query could not be translated into a query
/// string supported by the Microsoft Azure Mobile Service.
#define MSPredicateNotSupported                 -1400

/// Indicates that a request to the Microsoft Azure Mobile App failed because
/// a invalid parameter was passed to the function
#define MSInvalidParameter                      -1401

/// Indicates that the login operation has failed.
#define MSLoginFailed                           -1501

/// Indicates that the Microsoft Azure Mobile App returned a login response
/// with invalid syntax.
#define MSLoginInvalidResponseSyntax            -1502

/// Indicates that the login operation was canceled.
#define MSLoginCanceled                         -1503

/// Indicates that the login operation failed because a nil token was used.
#define MSLoginExpectedToken                    -1504

/// Indicates that the login operation failed because an invalid token was used.
#define MSLoginInvalidToken                     -1505

/// Indicates that the login operation failed because the gateway URL in the client
/// was invalid.
#define MSLoginInvalidURL                       -1506

/// Indicates that the refresh user operation failed because the identity provider
/// does not support refresh token or user is not logged in with sufficient permission
#define MSRefreshBadRequest                     -1511

/// Indicates that the refresh user operation failed because credentials are not valid
#define MSRefreshUnauthorized                   -1512

/// Indicates that the refresh user operation failed because refresh token was revoked
/// or expired
#define MSRefreshForbidden                      -1513

/// Indicates that the refresh user operation failed due to an unexpected error
#define MSRefreshUnexpectedError                -1514

/// Indicates that a required parameter for push operation was not provided
#define MSPushRequiredParameter                 -1600

/// Indicates that local storage is corrupt until register or deleteAllRegistrations are invoked
#define MSPushLocalStorageCorrupt               -1601

#endif
