//
//  WFSlideTextViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 3/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSlideTextViewController.h"
#import <MagicalRecord/MagicalRecord.h>
#import "WFAppDelegate.h"
#import "WFUtilities.h"
#import "Constants.h"
#import "UIMenuItem+ImageSupport.h"

@interface WFSlideTextViewController () <UIGestureRecognizerDelegate, UITextViewDelegate> {
    WFAppDelegate *delegate;
    CGFloat width;
    CGFloat height;
    UIPanGestureRecognizer *_panGesture;
    UITapGestureRecognizer *_doubleTapGesture;
    CGFloat keyboardHeight;
    UIBarButtonItem *backButton;
    UIBarButtonItem *leftAlignButton;
    UIBarButtonItem *rightAlignButton;
    UIBarButtonItem *centerAlignButton;
    UIImageView *navBarShadowView;
    NSNumber *positionX;
    NSNumber *positionY;
    NSNumber *textViewWidth;
    NSNumber *textViewHeight;
    CGFloat navBarHeight;
}

@end

@implementation WFSlideTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    width = screenWidth();
    height = screenHeight();
    [self.view setBackgroundColor:[UIColor blackColor]];
//    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
//    _panGesture.delegate = self;
//    [self.textView addGestureRecognizer:_panGesture];
//    _doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
//    _doubleTapGesture.delegate = self;
//    _doubleTapGesture.numberOfTapsRequired = 2;
//    [self.view addGestureRecognizer:_doubleTapGesture];
    
    [self.textView setKeyboardAppearance:UIKeyboardAppearanceDark];
    [self.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [self.textView setBackgroundColor:[UIColor clearColor]];
    [self.textView setTextColor:[UIColor whiteColor]];
    [self.textView setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self registerForKeyboardNotifications];
    
    self.slideshow = [self.slideshow MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    self.slide = [self.slide MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (self.slideText){
        [self.textView setText:self.slideText.body];
        if ([self.slideText.alignment isEqualToNumber:@(WFSlideTextAlignmentLeft)]){
            [self.textView setTextAlignment:NSTextAlignmentLeft];
        } else if ([self.slideText.alignment isEqualToNumber:@(WFSlideTextAlignmentRight)]){
            [self.textView setTextAlignment:NSTextAlignmentRight];
        } else {
            [self.textView setTextAlignment:NSTextAlignmentCenter];
        }
        positionX = self.slideText.positionX;
        positionY = self.slideText.positionY;
    }
    // set up the textView frame
    navBarHeight = self.navigationController.navigationBar.frame.size.height;
    [self.textView setFrame:CGRectMake(10, 10+navBarHeight, width-20, height - 20 - navBarHeight - keyboardHeight)];
    
    // set up the UINavigationBar buttons
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    leftAlignButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"leftAlign"] style:UIBarButtonItemStylePlain target:self action:@selector(leftAlign:)];
    rightAlignButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"rightAlign"] style:UIBarButtonItemStylePlain target:self action:@selector(rightAlign:)];
    centerAlignButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"centerAlign"] style:UIBarButtonItemStylePlain target:self action:@selector(centerAlign:)];
    self.navigationItem.rightBarButtonItems = @[rightAlignButton, centerAlignButton, leftAlignButton];
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"left"] style:UIBarButtonItemStylePlain target:self action:@selector(done)];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)leftAlign:(UIMenuController*)menuController {
    [self.textView setTextAlignment:NSTextAlignmentLeft];
}

- (void)rightAlign:(UIMenuController*)menuController {
    [self.textView setTextAlignment:NSTextAlignmentRight];
}

- (void)centerAlign:(UIMenuController*)menuController {
    [self.textView setTextAlignment:NSTextAlignmentCenter];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
    [self.textView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.textView becomeFirstResponder];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    
}

- (void)textViewDidChange:(UITextView *)textView {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview.superview];
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

- (void)handlePan:(UIPanGestureRecognizer*)gestureRecognizer {
    CGPoint translation = [gestureRecognizer locationInView:self.view];
    NSLog(@"translation %f, %f",translation.x, translation.y);
    gestureRecognizer.view.center = CGPointMake(gestureRecognizer.view.center.x + translation.x, gestureRecognizer.view.center.y + translation.y);
    [gestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.view.superview];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        positionX = @(self.textView.frame.origin.x);
        positionY = @(self.textView.frame.origin.y);
        textViewWidth = @(self.textView.frame.size.width);
        textViewHeight = @(self.textView.frame.size.height);
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
            
        }];
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer*)gestureRecognizer {
    [UIView animateWithDuration:kSlideResetAnimationDuration delay:0 usingSpringWithDamping:.975 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self.textView setFrame:CGRectMake(10, 10+navBarHeight, width-20, height - 20 - navBarHeight - keyboardHeight)];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note {
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameEndUserInfoKey];
    CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
    keyboardHeight = convertedKeyboardFrame.size.height;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.textView setFrame:CGRectMake(10, 10+navBarHeight, width-20, height-navBarHeight-keyboardHeight)];
                     } completion:^(BOOL finished) {
                         
                     }];
}

- (void)keyboardWillHide:(NSNotification *)note {
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameEndUserInfoKey];
    CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
    keyboardHeight = convertedKeyboardFrame.size.height;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.textView setFrame:CGRectMake(10, 10+navBarHeight, width-20, height-navBarHeight-keyboardHeight)];
                         
                     } completion:nil];
}

- (void)done {
    if (self.textView.text.length){
        if (self.slideText){
            [self.slideText setSlide:self.slide];
            [self.slideText setBody:self.textView.text];
            if (self.textView.textAlignment == NSTextAlignmentRight){
                [self.slideText setAlignment:@(WFSlideTextAlignmentRight)];
            } else if (self.textView.textAlignment == NSTextAlignmentLeft){
                [self.slideText setAlignment:@(WFSlideTextAlignmentLeft)];
            } else {
                [self.slideText setAlignment:@(WFSlideTextAlignmentCenter)];
            }
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                if (self.slideTextDelegate && [self.slideTextDelegate respondsToSelector:@selector(updatedSlideText:)]){
                    [self.slideTextDelegate updatedSlideText:self.slideText];
                }
                [self dismiss];
            }];
        } else {
            self.slideText = [SlideText MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
            [self.slideText setSlide:self.slide];
            [self.slideText setBody:self.textView.text];
            if (self.textView.textAlignment == NSTextAlignmentRight){
                [self.slideText setAlignment:@(WFSlideTextAlignmentRight)];
            } else if (self.textView.textAlignment == NSTextAlignmentLeft){
                [self.slideText setAlignment:@(WFSlideTextAlignmentLeft)];
            } else {
                [self.slideText setAlignment:@(WFSlideTextAlignmentCenter)];
            }
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                if (self.slideTextDelegate && [self.slideTextDelegate respondsToSelector:@selector(createdSlideText:)]){
                    [self.slideTextDelegate createdSlideText:self.slideText];
                }
                [self dismiss];
            }];
        }
    } else {
        [self dismiss];
    }
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
