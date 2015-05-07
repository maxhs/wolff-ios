//
//  WFNoRotateNavController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 4/18/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFNoRotateNavController.h"

@interface WFNoRotateNavController ()

@end

@implementation WFNoRotateNavController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    return NO;
}

@end
