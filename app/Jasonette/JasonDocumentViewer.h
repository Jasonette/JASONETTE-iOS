//
//  Header.h
//  Finalsite
//
//  Created by Gregory Ecklund on 11/1/18.
//  Copyright © 2018 Finalsite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

@interface JasonDocumentViewer : UIViewController <QLPreviewControllerDataSource, QLPreviewControllerDelegate>
    
@property (nonatomic, strong) NSString *fileURL;

@end
