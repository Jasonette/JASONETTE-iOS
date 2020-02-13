//
//  UILabelledSwitch.m
//  Finalsite
//
//  Created by Gregory Ecklund on 12/4/19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

#import "UILabelledSwitch.h"

@implementation UILabelledSwitch

- (id)init {
    
    self = [super init];
      
    labelView = [UILabel new];
    [self addArrangedSubview:labelView];
    switchView = [UISwitch new];
    [self addArrangedSubview:switchView];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapView:)];
    [self addGestureRecognizer:tapGestureRecognizer];
    [switchView addTarget:self action:@selector(switchUpdated:) forControlEvents:UIControlEventValueChanged];
    
   return self;
}

- (void)didTapView:(UITapGestureRecognizer *) recognizer {
    [self setOn:!self.isOn animated:YES];
}

- (void)setLabel:(NSString *) text {
    labelView.text = text;
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    self.isOn = on;
    [switchView setOn:self.isOn animated:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SwitchUpdated" object:self];
}

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityValue {
    return self.isOn ? @"1" : @"0";
}

- (NSString *)accessibilityLabel {
    return labelView.text;
}

- (UIAccessibilityTraits)accessibilityTraits {
    return switchView.accessibilityTraits;
}

- (BOOL)accessibilityActivate{
    [self setOn:!self.isOn animated:YES];
    return YES;
}

- (BOOL)isUserInteractionEnabled {
    return YES;
}

- (void) switchUpdated: (UISwitch *) switchView {
    self.isOn = switchView.isOn;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SwitchUpdated" object:self];
}

@end
