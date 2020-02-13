//
//  UILabelledSwitch.h
//  Finalsite
//
//  Created by Gregory Ecklund on 12/4/19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

#ifndef UILabelledSwitch_h
#define UILabelledSwitch_h

#import <UIKit/UIKit.h>

@interface UILabelledSwitch : UIStackView {
    UILabel *labelView;
    UISwitch *switchView;    
}

@property(nonatomic, assign) BOOL isOn;

- (id)init;
- (void)setLabel:(NSString *) text;
- (void)setOn:(BOOL)on animated:(BOOL)animated;

@end


#endif /* UILabelledSwitch_h */
