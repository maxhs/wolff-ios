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

@interface WFLoginViewController () <UIScrollViewDelegate,UITextFieldDelegate, WFLoginDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat height;
    CGFloat width;
    UIButton *doneEditingButton;
    BOOL login;
    CGFloat keyboardHeight;
    void (^completionBlock)();
}
@end

@implementation WFLoginViewController

@synthesize currentUser = _currentUser;

- (void)viewDidLoad
{
    [super viewDidLoad];
    delegate = [UIApplication sharedApplication].delegate;
    delegate.loginDelegate = self;
    manager = delegate.manager;
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemName] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    
    [_backButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];

    [self textFieldTreatment:_emailTextField];
    [_emailTextField setPlaceholder:@"albrecht@durer.com"];
    [self textFieldTreatment:_passwordTextField];
    [_passwordTextField setPlaceholder:@"password"];
    
    login = YES;
    [self setUpLoginButton];
    [self styleTermsButton];
    [self styleForgotPasswordButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_emailTextField becomeFirstResponder];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat x = scrollView.contentOffset.x;
    CGFloat pageWidth = scrollView.frame.size.width;
    int currentPage = floor((x - pageWidth / 2) / pageWidth) + 1;
    _pageControl.currentPage = currentPage;
}

- (void)incorrectEmail {
    [self addShakeAnimationForView:_emailTextField withDuration:.75f];
}

- (void)incorrectPassword {
    [self addShakeAnimationForView:_passwordTextField withDuration:.75f];
}

- (void)loginSuccessful {
    [self dismiss];
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
    
    //login from the delegate
    [delegate connectWithParameters:parameters];
    [self doneEditing];
}

- (void)forgotPassword:(id)sender {
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
        [parameters setObject:email forKey:@"email_address"];
        [manager POST:[NSString stringWithFormat:@"%@/password_resets",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success with password reset: %@",responseObject);
            if ([responseObject objectForKey:@"error"]){
                if ([[responseObject objectForKey:@"error"] isEqualToString:@"Email address not found."]){
                    [[[UIAlertView alloc] initWithTitle:@"No such luck." message:@"We couldn't find that email address in our system." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                }
            } else {
                
                #ifndef DEBUG
                                
                #else
                [[Mixpanel sharedInstance] track:@"Password reset"];
                #endif
                
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed with password reset: %@",error.description);
        }];
    } else {
        UIAlertView *forgotPasswordAlert = [[UIAlertView alloc] initWithTitle:@"Forgot Password" message:@"Please enter the email address associated with this account:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
        forgotPasswordAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[forgotPasswordAlert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
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
        if (textField == _emailTextField){
            [_passwordTextField becomeFirstResponder];
        } else if (textField == _passwordTextField) {
            [self connect];
        }
    } else if (textField == _passwordTextField){
        if (textField.text.length && _emailTextField.text.length){
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
    [webViewVC setUrl:[NSURL URLWithString:[NSString stringWithFormat:@"%@/home/terms",kBaseUrl]]];
    [webViewVC setTitle:@"Terms of Service"];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)doneEditing {
    [self.view endEditing:YES];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGRect rawKeyboardRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect properlyRotatedCoords = [self.view.window convertRect:rawKeyboardRect toView:self.view];
    NSNumber *animationDuration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    keyboardHeight = properlyRotatedCoords.size.height;
    NSNumber *curveValue = info[UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    
    [UIView animateWithDuration:animationDuration.doubleValue delay:0 options:(animationCurve << 16) animations:^{
        if (IDIOM == IPAD){
            if (login){
                _logoImageView.transform = CGAffineTransformMakeTranslation(0, -24);
                _emailTextField.transform = CGAffineTransformMakeTranslation(0, -50);
                _passwordTextField.transform = CGAffineTransformMakeTranslation(0, -50);
                _loginButton.transform = CGAffineTransformMakeTranslation(0, -50);
                _termsButton.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
                _forgotPasswordButton.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
            } else {
                _emailTextField.transform = CGAffineTransformMakeTranslation(0, -height/5);
                _passwordTextField.transform = CGAffineTransformMakeTranslation(0, -height/5);
                _firstNameTextField.transform = CGAffineTransformMakeTranslation(0, -height/5);
                _lastNameTextField.transform = CGAffineTransformMakeTranslation(0, -height/5);
                _loginButton.transform = CGAffineTransformMakeTranslation(0, -height/5);
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
    
    [UIView animateWithDuration:animationDuration.doubleValue delay:0 options:(animationCurve << 16) animations:^{
        _logoImageView.transform = CGAffineTransformIdentity;
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
    [self doneEditing];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Basic View Setup

- (void)styleForgotPasswordButton {
    [_forgotPasswordButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [_forgotPasswordButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_forgotPasswordButton setTitle:@"Forgot password?" forState:UIControlStateNormal];
    [_forgotPasswordButton addTarget:self action:@selector(forgotPassword:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)styleTermsButton {
    [_termsButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_termsButton.titleLabel setTextColor:[UIColor lightGrayColor]];
    NSMutableAttributedString *termsString = [[NSMutableAttributedString alloc] initWithString:@"By continuing, you agree to our " attributes:nil];
    NSMutableAttributedString *linkString = [[NSMutableAttributedString alloc] initWithString:@"Terms of Service" attributes:@{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]}];
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
    [textField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.7]];
    [textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    textField.layer.borderColor = [UIColor colorWithWhite:.9 alpha:1].CGColor;
    textField.layer.borderWidth = .5f;
    textField.layer.cornerRadius = 2.f;
    textField.clipsToBounds = YES;
    [textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    textField.leftView = paddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
