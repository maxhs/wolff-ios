//
//  WFRightMenuTableViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 4/19/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFRightMenuTableViewController.h"
#import "Constants.h"
#import "WFUtilities.h"

@interface WFRightMenuTableViewController () {
    UIImageView *navBarShadowView;
}

@end

@implementation WFRightMenuTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 64.f;
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:0]];
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = dismissButton;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RightMenuCell" forIndexPath:indexPath];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    switch (indexPath.row) {
        case 0:
            [cell.imageView setImage:[UIImage imageNamed:@"whitePlus"]];
            [cell.textLabel setText:@"Add Art"];
            break;
        case 1:
            [cell.imageView setImage:[UIImage imageNamed:@"whiteAlert"]];
            [cell.textLabel setText:@"Notifications"];
            break;
        case 2:
            [cell.imageView setImage:[UIImage imageNamed:@"settings"]];
            [cell.textLabel setText:@"Settings"];
            break;
        case 3:
            [cell.imageView setImage:[UIImage imageNamed:@"whiteLogout"]];
            [cell.textLabel setText:@"Log Out"];
            break;
            
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            [self showNewArt];
            break;
        case 1:
            [self showNotifications];
            break;
        case 2:
            [self showSettings];
            break;
        case 3:
            [self logout];
            break;
            
        default:
            break;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self dismiss];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

- (void)showNewArt {
    if (self.rightMenuDelegate && [self.rightMenuDelegate respondsToSelector:@selector(showNewArt)]){
        [self.rightMenuDelegate showNewArt];
    }
}

- (void)showSettings {
    if (self.rightMenuDelegate && [self.rightMenuDelegate respondsToSelector:@selector(showSettings)]){
        [self.rightMenuDelegate showSettings];
    }
}

- (void)showNotifications {
    if (self.rightMenuDelegate && [self.rightMenuDelegate respondsToSelector:@selector(showNotifications)]){
        [self.rightMenuDelegate showNotifications];
    }
}

- (void)logout {
    if (self.rightMenuDelegate && [self.rightMenuDelegate respondsToSelector:@selector(logout)]){
        [self.rightMenuDelegate logout];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dismiss {
    [UIView animateWithDuration:kFastAnimationDuration animations:^{
        [self.view setAlpha:0.0];
        self.navigationItem.rightBarButtonItem = nil;
    }];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Dispose of any resources that can be recreated.
}

@end
