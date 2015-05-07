//
//  WFLoginViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 6/18/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFAppDelegate.h"
#import "WFLoginViewController.h"
#import "WFWebViewController.h"
#import <Mixpanel/Mixpanel.h>
#import "WFAlert.h"

@interface WFLoginViewController () <UIScrollViewDelegate,UITextFieldDelegate, WFLoginDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat height;
    CGFloat width;
    UIButton *doneEditingButton;
    BOOL signup;
    BOOL keyboardShowing;
    CGFloat keyboardHeight;
    void (^completionBlock)();
}
@end

@implementation WFLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = [UIApplication sharedApplication].delegate;
    delegate.loginDelegate = self;
    manager = delegate.manager;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.view setBackgroundColor:[UIColor clearColor]];
    if (IDIOM != IPAD) {
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
    
    if (SYSTEM_VERSION >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }

    [self textFieldTreatment:_emailTextField];
    [_emailTextField setPlaceholder:@"albrecht@durer.com"];
    [self textFieldTreatment:_passwordTextField];
    [_passwordTextField setPlaceholder:@"password"];
    [self textFieldTreatment:_firstNameTextField];
    [self textFieldTreatment:_lastNameTextField];
    signup = NO;
    [_backButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self setUpLoginButton];
    [self styleTermsButton];
    [self styleForgotPasswordButton];
    [_switchModesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_switchModesButton addTarget:self action:@selector(switchModes) forControlEvents:UIControlEventTouchUpInside];
    [_switchModesButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    CGRect switchFrame = self.switchModesButton.frame;
    switchFrame.origin.x = self.view.frame.size.width-switchFrame.size.width-20;
    [self.switchModesButton setFrame:switchFrame];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.emailTextField becomeFirstResponder];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //CGFloat x = scrollView.contentOffset.x;
    //CGFloat pageWidth = scrollView.frame.size.width;
    //int currentPage = floor((x - pageWidth / 2) / pageWidth) + 1;
    //_pageControl.currentPage = currentPage;
}

- (void)switchModes {
    if (signup){
        [_switchModesButton setTitle:@"Sign up" forState:UIControlStateNormal];
        [_forgotPasswordButton setHidden:NO];
        [_emailTextField becomeFirstResponder];
        signup = NO;
        [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.77 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [_loginButton setTitle:@"LOGIN" forState:UIControlStateNormal];
            [_firstNameTextField setAlpha:0.0];
            [_lastNameTextField setAlpha:0.0];
            [_forgotPasswordButton setAlpha:1.0];
            if (keyboardShowing){
                _emailTextField.transform = CGAffineTransformMakeTranslation(0, -50);
                _passwordTextField.transform = CGAffineTransformMakeTranslation(0, -50);
                _loginButton.transform = CGAffineTransformMakeTranslation(0, -50);
            }
        } completion:^(BOOL finished) {
            
            [_firstNameTextField setHidden:YES];
            [_lastNameTextField setHidden:YES];
        }];
    } else {
        [_switchModesButton setTitle:@"Log in" forState:UIControlStateNormal];
        [_firstNameTextField setAlpha:0.0];
        [_lastNameTextField setAlpha:0.0];
        [_firstNameTextField setHidden:NO];
        [_lastNameTextField setHidden:NO];
        
        signup = YES;
        [_firstNameTextField becomeFirstResponder];
        
        [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.77 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [_loginButton setTitle:@"SIGNUP" forState:UIControlStateNormal];
            [_firstNameTextField setAlpha:1.0];
            [_lastNameTextField setAlpha:1.0];
            [_forgotPasswordButton setAlpha:0.0];
            if (keyboardShowing){
                _emailTextField.transform = CGAffineTransformMakeTranslation(0, 0);
                _passwordTextField.transform = CGAffineTransformMakeTranslation(0, 0);
                _loginButton.transform = CGAffineTransformMakeTranslation(0, 0);
            }
        } completion:^(BOOL finished) {
            
            [_forgotPasswordButton setHidden:YES];
        }];
    }
}

- (void)userAlreadyExists {
    [self addShakeAnimationForView:_emailTextField withDuration:.77f];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (double).6f * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [WFAlert show:@"We already have that email address on file. Please try logging in instead!" withTime:3.3f];
    });
    dispatch_time_t secondPopTime = dispatch_time(DISPATCH_TIME_NOW, (double)2.f * NSEC_PER_SEC);
    dispatch_after(secondPopTime, dispatch_get_main_queue(), ^(void){
        [self switchModes];
    });
}

- (void)incorrectEmail {
    [self addShakeAnimationForView:_emailTextField withDuration:.77f];
}
- (void)incorrectPassword {
    [self addShakeAnimationForView:_passwordTextField withDuration:.77f];
}

- (void)loginSuccessful {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)logout {

}

- (void)connect {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if (_emailTextField.text.length){
        [parameters setObject:_emailTextField.text forKey:@"email"];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Please include a valid email / username before logging in." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        return;
    }
    if (_passwordTextField.text.length) {
        [parameters setObject:_passwordTextField.text forKey:@"password"];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Please add a password before logging in." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        return;
    }
    if (signup){
        if (_firstNameTextField.text.length) {
            [parameters setObject:_firstNameTextField.text forKey:@"first_name"];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Please make sure you've added your first name before signing up." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            return;
        }
        if (_lastNameTextField.text.length) {
            [parameters setObject:_lastNameTextField.text forKey:@"last_name"];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Please make sure you've added your last name before signing up." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            return;
        }
    }
    
    [delegate connectWithParameters:parameters forSignup:signup]; // connect is in the app delegate!
    [self doneEditing];
}

- (void)forgotPassword:(id)sender {
    [self.view endEditing:YES];
    NSString *email;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([sender isKindOfClass:[NSString class]]){
        email = sender;
    } else {
        if (_emailTextField.text.length){
            email = _emailTextField.text;
        }
    }
    
    if (email.length){
        [parameters setObject:email forKey:@"email"];
        [manager POST:[NSString stringWithFormat:@"%@/forgot_password",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success with password reset: %@",responseObject);
            if ([responseObject objectForKey:@"error"]){
                if ([[responseObject objectForKey:@"error"] isEqualToString:@"Email address not found."]){
                    [[[UIAlertView alloc] initWithTitle:@"No such luck." message:@"We couldn't find that email address in our system." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                }
            } else {
                [WFAlert show:@"We've sent password reset instructions to the email on file." withTime:2.7f];
                #ifndef DEBUG
                                
                #else
                [[Mixpanel sharedInstance] track:@"Password reset"];
                #endif
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed with password reset: %@",error.description);
        }];
    } else {
        UIAlertView *forgotPasswordAlert = [[UIAlertView alloc] initWithTitle:@"Password Reset" message:@"Please enter your account's email address:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
        forgotPasswordAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[forgotPasswordAlert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
        [[forgotPasswordAlert textFieldAtIndex:0] setKeyboardAppearance:UIKeyboardAppearanceDark];
        [forgotPasswordAlert show];
    }
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
        [self forgotPassword:[[alertView textFieldAtIndex:0] text]];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (doneEditingButton.isHidden){
        [doneEditingButton setHidden:NO];
        
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        if (textField == _firstNameTextField){
            [_lastNameTextField becomeFirstResponder];
        } else if (textField == _lastNameTextField){
            [_emailTextField becomeFirstResponder];
        } else if (textField == _emailTextField){
            [_passwordTextField becomeFirstResponder];
        } else if (textField == _passwordTextField) {
            [self connect];
        }
    } else {
        if (_passwordTextField.text.length && _emailTextField.text.length){
            [_loginButton setBackgroundColor:[UIColor blackColor]];
            [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else {
            [_loginButton setBackgroundColor:[UIColor clearColor]];
            [_loginButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        }
    }
    return YES;
}

- (void)termsWebView {
    WFWebViewController *webViewVC = [[self storyboard] instantiateViewControllerWithIdentifier:@"WebView"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:webViewVC];
    [webViewVC setUrl:[NSURL URLWithString:[NSString stringWithFormat:@"%@/terms",kBaseUrl]]];
    [webViewVC setTitle:@"Terms of Service"];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)doneEditing {
    [self.view endEditing:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (IDIOM == IPAD){
            
        } else {
            UIImageView *blurredButton = (UIImageView*)[self.view.window viewWithTag:kBlurredBackgroundConstant];
            CGRect buttonRect = blurredButton.frame;
            buttonRect.size.width = size.width;
            buttonRect.size.height = size.height;
            [blurredButton setFrame:buttonRect];
            CGRect switchModesFrame = self.switchModesButton.frame;
            switchModesFrame.origin.x = size.width-switchModesFrame.size.width-20;
            [self.switchModesButton setFrame:switchModesFrame];

        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGRect rawKeyboardRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect properlyRotatedCoords = [self.view.window convertRect:rawKeyboardRect toView:self.view];
    NSNumber *animationDuration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    keyboardHeight = properlyRotatedCoords.size.height;
    NSNumber *curveValue = info[UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    keyboardShowing = YES;
    
    [UIView animateWithDuration:animationDuration.doubleValue delay:0 options:(animationCurve << 16) animations:^{
        if (IDIOM == IPAD){
            if (signup){
                _emailTextField.transform = CGAffineTransformMakeTranslation(0, -20);
                _passwordTextField.transform = CGAffineTransformMakeTranslation(0, -20);
                _firstNameTextField.transform = CGAffineTransformMakeTranslation(0, -20);
                _lastNameTextField.transform = CGAffineTransformMakeTranslation(0, -20);
                _loginButton.transform = CGAffineTransformMakeTranslation(0, -20);
                _logoImageView.transform = CGAffineTransformMakeTranslation(0, -54);
                _termsButton.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
                _forgotPasswordButton.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
            } else {
                _logoImageView.transform = CGAffineTransformMakeTranslation(0, -36);
                _emailTextField.transform = CGAffineTransformMakeTranslation(0, -60);
                _passwordTextField.transform = CGAffineTransformMakeTranslation(0, -60);
                _loginButton.transform = CGAffineTransformMakeTranslation(0, -52);
                _termsButton.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
                _forgotPasswordButton.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
            }
        } else {
            if (signup){
                _termsButton.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
                _forgotPasswordButton.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
            } else {
                _emailTextField.transform = CGAffineTransformMakeTranslation(0, -50);
                _passwordTextField.transform = CGAffineTransformMakeTranslation(0, -50);
                _loginButton.transform = CGAffineTransformMakeTranslation(0, -50);
                _termsButton.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
                _forgotPasswordButton.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
            }
        }
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    NSNumber *animationDuration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];
    keyboardHeight = keyboardFrame.size.height;
    NSNumber *curveValue = info[UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    keyboardShowing = NO;
    
    [UIView animateWithDuration:animationDuration.doubleValue delay:0 options:(animationCurve << 16) animations:^{
        if (signup){
            
        } else {
            _logoImageView.transform = CGAffineTransformIdentity;
        }
        _emailTextField.transform = CGAffineTransformIdentity;
        _firstNameTextField.transform = CGAffineTransformIdentity;
        _lastNameTextField.transform = CGAffineTransformIdentity;
        _passwordTextField.transform = CGAffineTransformIdentity;
        _loginButton.transform = CGAffineTransformIdentity;
        _termsButton.transform = CGAffineTransformIdentity;
        _forgotPasswordButton.transform = CGAffineTransformIdentity;
        
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - Shake Animation

- (void)addShakeAnimationForView:(UIView *)view withDuration:(NSTimeInterval)duration {
    CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.delegate = self;
    animation.duration = duration;
    animation.values = @[ @(0), @(10), @(-8), @(8), @(-5), @(5), @(0) ];
    animation.keyTimes = @[ @(0), @(0.225), @(0.425), @(0.6), @(0.75), @(0.875), @(1) ];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [view.layer addAnimation:animation forKey:@"WolffShake"];
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag {
    if ( completionBlock ) {
        completionBlock();
    }
}

- (void)dismiss {
    if (keyboardShowing){
        [self doneEditing];
    } else {
        [self doneEditing];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    }
}

#pragma mark - Basic View Setup

- (void)styleForgotPasswordButton {
    [_forgotPasswordButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [_forgotPasswordButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_forgotPasswordButton setTitle:@"Forget your password?" forState:UIControlStateNormal];
    [_forgotPasswordButton addTarget:self action:@selector(forgotPassword:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)styleTermsButton {
    [_termsButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_termsButton.titleLabel setTextColor:[UIColor lightGrayColor]];
    NSMutableAttributedString *termsString = [[NSMutableAttributedString alloc] initWithString:@"By continuing, you agree to our " attributes:nil];
    NSMutableAttributedString *linkString = [[NSMutableAttributedString alloc] initWithString:@"Terms" attributes:@{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]}];
    [termsString appendAttributedString:linkString];
    _termsButton.titleLabel.numberOfLines = 0;
    _termsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_termsButton setAttributedTitle:termsString forState:UIControlStateNormal];
    [_termsButton addTarget:self action:@selector(termsWebView) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setUpLoginButton {
    [_loginButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    _loginButton.layer.borderWidth = 1.f;
    _loginButton.layer.cornerRadius = 14.f;
    _loginButton.layer.borderColor = [UIColor colorWithWhite:.825 alpha:0].CGColor;
    [_loginButton addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
    [_loginButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
}

- (void)textFieldTreatment:(UITextField*)textField {
    if (IDIOM == IPAD){
        [textField setBackgroundColor:kTextFieldBackground];
    } else {
        [textField setBackgroundColor:[UIColor whiteColor]];
    }
    [textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    textField.layer.cornerRadius = 2.f;
    textField.clipsToBounds = YES;
    [textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    textField.leftView = paddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
