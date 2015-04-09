//
//  WFSlideTextViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 3/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSlideTextViewController.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "WFAppDelegate.h"
#import "WFUtilities.h"
#import "Constants.h"

@interface WFSlideTextViewController () <UIGestureRecognizerDelegate, UITextViewDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    UIPanGestureRecognizer *_panGesture;
    CGFloat keyboardHeight;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *backButton;
    BOOL iOS8;
    UIImageView *navBarShadowView;
}

@end

@implementation WFSlideTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    if (SYSTEM_VERSION >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
    }
    [self.view setBackgroundColor:[UIColor blackColor]];
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGesture.delegate = self;
    [self.view addGestureRecognizer:_panGesture];
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
    }
    
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem = doneButton;
    backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = backButton;
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.textView becomeFirstResponder];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handlePan:(UIPanGestureRecognizer*)gestureRecognizer {
    CGPoint translation = [gestureRecognizer locationInView:self.view];
    
    CGPoint newPoint = CGPointMake(gestureRecognizer.view.center.x + translation.x, gestureRecognizer.view.center.y + translation.y);
    gestureRecognizer.view.center = newPoint;
    [gestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.view];
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
                         self.textView.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight/2);
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
                         //self.textView.transform = CGAffineTransformIdentity;
                     } completion:nil];
}

- (void)done {
    if (self.textView.text.length){
        if (self.slideText){
            [self.slideText setSlide:self.slide];
            [self.slideText setBody:self.textView.text];
        } else {
            self.slideText = [SlideText MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [self.slideText setSlide:self.slide];
            [self.slideText setBody:self.textView.text];
        }
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        NSMutableDictionary *slideTextDict = [NSMutableDictionary dictionary];
        [parameters setObject:self.slideText.slide.identifier forKey:@"slide_id"];
        [slideTextDict setObject:self.slideText.body forKey:@"body"];
        [parameters setObject:slideTextDict forKey:@"slide_text"];

        if ([self.slideText.identifier isEqualToNumber:@0]){
            [manager POST:@"slide_texts" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Success creating slide text: %@",responseObject);
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to create slide text: %@",error.description);
            }];
        } else {
            [manager PATCH:[NSString stringWithFormat:@"slide_texts/%@",self.slideText.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Success updating slide text: %@",responseObject);
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to update slide text: %@",error.description);
            }];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self dismiss];
        }];
    } else {
        [self dismiss];
    }
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.slideText) {
        if (self.slideTextDelegate && [self.slideTextDelegate respondsToSelector:@selector(updatedSlideText:)]){
            [self.slideTextDelegate updatedSlideText:self.slideText];
        }
    } else {
        if (self.slideTextDelegate && [self.slideTextDelegate respondsToSelector:@selector(updatedSlideText:)]){
            [self.slideTextDelegate updatedSlideText:self.slideText];
        }
    }
    
}

@end
