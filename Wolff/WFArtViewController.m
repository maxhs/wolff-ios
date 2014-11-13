//
//  WFArtViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFAppDelegate.h"
#import "WFArtViewController.h"
#import "WFArtMetadataAnimator.h"

@interface WFArtViewController () {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
}

@end

@implementation WFArtViewController
@synthesize art = _art;


- (void)viewDidLoad
{
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
