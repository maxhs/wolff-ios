//
//  WFDatePicker.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFDatePicker.h"
#import "Constants.h"

const NSUInteger NUM_COMPONENTS = 4;
typedef enum {
    kWFDatePickerInvalid = 0,
    kWFDatePickerEra,
    kWFDatePickerYear,
    kWFDatePickerCirca
} WFDatePickerComponent;


@interface WFDatePicker () <UIPickerViewDataSource, UIPickerViewDelegate> {
    WFDatePickerComponent _components[NUM_COMPONENTS];
    NSInteger era;
    BOOL circa;
}

@property (nonatomic, retain, readwrite) NSCalendar *calendar;
@property (nonatomic, retain, readwrite) NSDateFormatter *dateFormatter;
@property (nonatomic, retain, readwrite) NSDateComponents *currentDateComponents;
@property (nonatomic, retain, readwrite) UIFont *font;

@end

@implementation WFDatePicker

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (!self) return nil;
    
    [self commonInit];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (!self) {
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (void)commonInit {
    self.tintColor = [UIColor whiteColor];
    self.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0];
    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [self setLocale:[NSLocale currentLocale]];
    self.picker = [[UIPickerView alloc] initWithFrame:self.bounds];
    self.picker.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.picker.dataSource = self;
    self.picker.delegate = self;
    [self.picker setBackgroundColor:[UIColor clearColor]];
    self.picker.tintColor = [UIColor whiteColor];
    self.date = [NSDate date];
    [self setMinimumDate:[NSDate date]];
    [self addSubview:self.picker];
    [self setBackgroundColor:[UIColor clearColor]];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(320.f, 216.0f);
}

#pragma mark - Setup

- (void)setMinimumDate:(NSDate *)minimumDate {
    _minimumDate = minimumDate;
    [self updateComponents];
}

- (void)setMaximumDate:(NSDate *)maximumDate {
    
    _maximumDate = maximumDate;
    [self updateComponents];
}

- (void)setDate:(NSDate *)date {
    [self setDate:date animated:NO];
}

- (void)setDate:(NSDate *)date animated:(BOOL)animated {
    self.currentDateComponents = [self.calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit /*| NSMinuteCalendarUnit*/)
                                                  fromDate:date];
    
    [self.picker reloadAllComponents];
    [self setIndicesAnimated:YES];
}

- (NSDate *)date {
    return [self.calendar dateFromComponents:self.currentDateComponents];
}

- (void)setLocale:(NSLocale *)locale {
    self.calendar.locale = locale;
    [self updateComponents];
}

- (WFDatePickerComponent)componentFromLetter:(NSString *)letter {
    if ([letter isEqualToString:@"y"]) {
        return kWFDatePickerYear;
    } else {
        return kWFDatePickerInvalid;
    }
}

- (WFDatePickerComponent)thirdComponentFromFirstComponent:(WFDatePickerComponent)component1
                                       andSecondComponent:(WFDatePickerComponent)component2 {
    
    NSMutableIndexSet *set = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(kWFDatePickerInvalid + 1, NUM_COMPONENTS)];
    [set removeIndex:component1];
    [set removeIndex:component2];
    
    return (WFDatePickerComponent) [set firstIndex];
}

- (void)updateComponents {
    _components[0] = kWFDatePickerYear;
    _components[1] = kWFDatePickerEra;
    _components[2] = kWFDatePickerCirca;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.calendar = self.calendar;
    self.dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    [self.picker reloadAllComponents];
    
    [self setIndicesAnimated:NO];
}

- (void)setIndexForComponentIndex:(NSUInteger)componentIndex animated:(BOOL)animated {
    WFDatePickerComponent component = [self componentForIndex:componentIndex];
    NSRange unitRange = [self rangeForComponent:component];
    NSInteger value;
    
    if (component == kWFDatePickerEra) {
        value = self.currentDateComponents.era;
    } else if (component == kWFDatePickerYear) {
        value = self.currentDateComponents.year;
    }

    NSInteger index = (value - unitRange.location);
    NSInteger middleIndex = (INT16_MAX / 2) - (INT16_MAX / 2) % unitRange.length + index;
    
    if (component == kWFDatePickerYear) {
        [self.picker selectRow:middleIndex inComponent:componentIndex animated:animated];
    }
}

- (void)setIndicesAnimated:(BOOL)animated {
    for (NSUInteger componentIndex = 0; componentIndex < NUM_COMPONENTS; componentIndex++) {
        [self setIndexForComponentIndex:componentIndex animated:animated];
    }
}

- (WFDatePickerComponent)componentForIndex:(NSInteger)componentIndex {
    return _components[componentIndex];
}

- (NSCalendarUnit)unitForComponent:(WFDatePickerComponent)component {
    if (component == kWFDatePickerEra) {
        return NSYearCalendarUnit;
    } else if (component == kWFDatePickerYear) {
        return NSYearCalendarUnit;
    } else if (component == kWFDatePickerCirca) {
        return NSMonthCalendarUnit;
    } else {
        return NSMinuteCalendarUnit;
        assert(NO);
    }
}

- (NSRange)rangeForComponent:(WFDatePickerComponent)component {
    NSCalendarUnit unit = [self unitForComponent:component];
    return [self.calendar maximumRangeOfUnit:unit];
}

#pragma mark - Data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)componentIndex {
    if (componentIndex == 1 || componentIndex == 2){
        return 2;
    } else {
        return INT16_MAX;
    }
}

#pragma mark - Delegate

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)componentIndex {
    WFDatePickerComponent component = [self componentForIndex:componentIndex];
    
    if (component == kWFDatePickerYear) {
        CGSize size = [@"0000" sizeWithAttributes:@{NSFontAttributeName : self.font}];
        return size.width + 10.0f;
    } else if (component == kWFDatePickerCirca) {
        CGSize size = [@" Circa " sizeWithAttributes:@{NSFontAttributeName : self.font}];
        return size.width + 10.0f;
    } else if (component == kWFDatePickerEra) {
        CGSize size = [@" CE " sizeWithAttributes:@{NSFontAttributeName : self.font}];
        return size.width + 10.0f;
    } else {
        return 0.01f;
    }
}

- (NSString *)titleForRow:(NSInteger)row forComponent:(WFDatePickerComponent)component {
    NSRange unitRange = [self rangeForComponent:component];
    NSInteger value = unitRange.location + (row % unitRange.length);
    
    if (component == kWFDatePickerYear) {
        return [NSString stringWithFormat:@"%li", (long) value];
    } else if (component == kWFDatePickerEra) {
        if (row == 0){
            return @"CE";
        } else {
            return @"BCE";
        }
    } else if (component == kWFDatePickerCirca) {
        if (row == 0){
            return @"";
        } else {
            return @"Circa";
        }
    } else {
        return @"";
    }
}

- (NSInteger)valueForRow:(NSInteger)row andComponent:(WFDatePickerComponent)component {
    NSRange unitRange = [self rangeForComponent:component];
    return (row % unitRange.length) + unitRange.location;
}

- (BOOL)isEnabledRow:(NSInteger)row forComponent:(NSInteger)componentIndex {
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = self.currentDateComponents.year;
    dateComponents.month = self.currentDateComponents.month;
    dateComponents.day = self.currentDateComponents.day;
    dateComponents.hour = self.currentDateComponents.hour;
    WFDatePickerComponent component = [self componentForIndex:componentIndex];
    NSInteger value = [self valueForRow:row andComponent:component];
    
    if (component == kWFDatePickerYear) {
        dateComponents.year = value;
    }
    
    NSDate *rowDate = [self.calendar dateFromComponents:dateComponents];
    
    if (_minimumDate != nil && [_minimumDate compare:rowDate] == NSOrderedDescending) {
        return NO;
    }
    else if (self.maximumDate != nil && [rowDate compare:self.maximumDate] == NSOrderedDescending) {
        return NO;
    }
    
    return YES;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)componentIndex reusingView:(UIView *)view {
    UILabel *label;
    
    if ([view isKindOfClass:[UILabel class]]) {
        label = (UILabel *) view;
    } else {
        label = [[UILabel alloc] init];
        label.font = self.font;
    }
    
    WFDatePickerComponent component = [self componentForIndex:componentIndex];
    NSString *title = [self titleForRow:row forComponent:component];
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    label.attributedText = attributedTitle;
    label.textAlignment = NSTextAlignmentCenter;
    
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)componentIndex {
    WFDatePickerComponent component = [self componentForIndex:componentIndex];
    NSInteger value = [self valueForRow:row andComponent:component];
    
    if (component == kWFDatePickerYear) {
        self.currentDateComponents.year = value;
    } else if (component == kWFDatePickerEra) {
        era = value;
    } else if (component == kWFDatePickerCirca) {
        circa = row == 1 ? NO : YES ;
    } else {
        //assert(NO);
    }
    
    [self setIndexForComponentIndex:componentIndex animated:NO];
    
    NSDate *datePicked = self.date;
    if (self.datePickerDelegate && [self.datePickerDelegate respondsToSelector:@selector(dateSelected:suffix:circa:)]){
        NSString *suffix = era == 2 ? @"BCE" : @"CE";
        
        [self.datePickerDelegate dateSelected:datePicked suffix:suffix circa:circa];
    }
//    if (self.minimumDate != nil && [datePicked compare:self.minimumDate] == NSOrderedAscending) {
//        //[self setDate:self.minimumDate animated:YES];
//        [[[UIAlertView alloc] initWithTitle:@"Date selection" message:@"You've selected a reminder date in the past. Did you really mean to do this?" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
//    }
//    else if (self.maximumDate != nil && [datePicked compare:self.maximumDate] == NSOrderedDescending) {
//        [self setDate:self.maximumDate animated:YES];
//    }
//    else {
        [self.picker reloadAllComponents];
    //}
}

@end
