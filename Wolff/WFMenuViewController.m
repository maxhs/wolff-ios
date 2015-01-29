//
//  WFMenuViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/21/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFMenuViewController.h"
#import "WFMenuCell.h"
#import "WFAppDelegate.h"
#import "WFAlert.h"

@interface WFMenuViewController () {
    WFAppDelegate *delegate;
}

@end

@implementation WFMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.rowHeight = 50.f;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
    UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
    [selectedView setBackgroundColor:[UIColor colorWithWhite:0 alpha:.1]];
    cell.selectedBackgroundView = selectedView;
    
    switch (indexPath.row) {
        /*case 0:
            [cell.imageView setImage:[UIImage imageNamed:@"cloudDownload"]];
            [cell.textLabel setText:@" Local Backup"];
            break;*/
        case 0:
            [cell.imageView setImage:[UIImage imageNamed:@"blackSettings"]];
            [cell.textLabel setText:@" Account"];
            break;
        case 1:
            [cell.imageView setImage:[UIImage imageNamed:@"profile"]];
            [cell.textLabel setText:@" Profile"];
            break;
        case 2:
            [cell.imageView setImage:[UIImage imageNamed:@"logout"]];
            [cell.textLabel setText:@" Log Out"];
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        /*case 0:
            
            break;*/
        case 0:
            if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(showSettings)]) {
                [self.menuDelegate showSettings];
            }
            break;
        case 1:
            if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(showProfile)]) {
                [self.menuDelegate showProfile];
            }
            break;
        case 2:
            [delegate logout];
            if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(logout)]) {
                [self.menuDelegate logout];
            }
            break;
            
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
