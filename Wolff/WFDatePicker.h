//
//  WFDatePicker.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol WFDatePickerDelegate <NSObject>
- (void)dateSelected:(NSDate*)date suffix:(NSString*)suffix circa:(BOOL)circa;
@end

@interface WFDatePicker : UIControl
@property (nonatomic, retain, readwrite) NSDate *minimumDate;
@property (nonatomic, retain, readwrite) NSDate *maximumDate;
@property (nonatomic, assign, readwrite) NSDate *date;
@property (strong, nonatomic) UIPickerView *picker;
@property (weak, nonatomic) id<WFDatePickerDelegate>datePickerDelegate;
- (void)setDate:(NSDate *)date animated:(BOOL)animated;
@end
