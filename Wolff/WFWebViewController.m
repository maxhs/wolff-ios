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

- (void)viewDidLoad
{
    [super viewDidLoad];
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:_url];
    NSLog(@"request obj: %@",requestObj);
    [_webView loadRequest:requestObj];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
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
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to load. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
