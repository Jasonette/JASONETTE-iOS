//
//  NSString+DTUTI.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 03.10.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Utility methods that work with Universal Type Identifiers (UTI).
 */

@interface NSString (DTUTI)


/**-------------------------------------------------------------------------------------
 @name Working with UTIs
 ---------------------------------------------------------------------------------------
 */

/**
 Method to get the recommended MIME-Type for the given file extension. If no MIME-Type can be determined then 'application/octet-stream' is returned.
 @param extension the file extension
 @return the recommended MIME-Type for the given path extension.
*/
+ (NSString *)MIMETypeForFileExtension:(NSString *)extension;


/**
 Method to get the official description for a given file extension.
 @param extension the file extension
 @return the description
 */
+ (NSString *)fileTypeDescriptionForFileExtension:(NSString *)extension;


/**
 Method to get the preferred UTI for a given file extension.
 @param extension the file extension
 @return the UTI
 */
+ (NSString *)universalTypeIdentifierForFileExtension:(NSString *)extension;

/**
 Get the prefered file extension for a given UTI.
 @param UTI he UTI
 @returns The File Extension
 */
+ (NSString *)fileExtensionForUniversalTypeIdentifier:(NSString *)UTI;

/**
 Tests if the receiver conforms to a given UTI.
 @param conformingUTI the UTI that is tested against
 @return `YES` if the receiver conforms
 */
- (BOOL)conformsToUniversalTypeIdentifier:(NSString *)conformingUTI;

/**
 @returns `YES` if the receiver is a movie file name
 */
- (BOOL)isMovieFileName;

/**
 @Returns `YES` if the receiver is an audio file name
 */
- (BOOL)isAudioFileName;

/**
 @Returns `YES` if the receiver is an image file name
 */
- (BOOL)isImageFileName;

/**
 @Returns `YES` if the receiver is an HTML file name
 */
- (BOOL)isHTMLFileName;

@end
