//
//  WFWebViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFWebViewController.h"
#import "WFAppDelegate.h"

@interface WFWebViewController () <UIWebViewDelegate> {
    UIBarButtonItem *backButton;
}

@end

@implementation WFWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:_url];
    [_webView loadRequest:requestObj];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [ProgressHUD dismiss];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [ProgressHUD show:@"Loading..."];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error){
        [ProgressHUD dismiss];
        //[[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to load this page. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"what was the error: %@",error.description);
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
