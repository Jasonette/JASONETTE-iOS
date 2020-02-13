//
//  JasonDocumentViewer.m
//  Finalsite
//
//  Created by Gregory Ecklund on 11/1/18.
//  Copyright © 2018 Finalsite. All rights reserved.
//

#import "JasonDocumentViewer.h"

@implementation JasonDocumentViewer

#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Quick Look";
}

#pragma mark QLPreviewControllerDelegate methods
- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    
    return YES;
}


#pragma mark QLPreviewControllerDataSource methods
- (NSInteger) numberOfPreviewItemsInPreviewController: (QLPreviewController *) controller {

    return 1;
}

- (id <QLPreviewItem>) previewController: (QLPreviewController *) controller previewItemAtIndex: (NSInteger) index {
    NSURL *fileUrl = [NSURL fileURLWithPath: self.fileURL];
    return fileUrl;
}

#pragma mark Memory management
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

@end
