//
//  WFNotificationsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFNotificationsViewController.h"
#import "WFAppDelegate.h"
#import "WFNotificationCell.h"
#import <DateTools/DateTools.h>
#import "WFUtilities.h"

@interface WFNotificationsViewController () <UIAlertViewDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UIRefreshControl *refresh;
    NSMutableArray *_notifications;
    Notification *_notificationToDelete;
    NSIndexPath *indexPathForDeletion;
    UIImageView *navBarShadowView;
}

@end

@implementation WFNotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    if (IDIOM == IPAD){
        
    } else {
        UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
        [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
        [backgroundToolbar setTranslucent:YES];
        [self.tableView setBackgroundView:backgroundToolbar];
        
        UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismiss)];
        self.navigationItem.leftBarButtonItem = dismissButton;
        navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        self.title = @"Notifications";
    }
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.14]];
    self.tableView.rowHeight = 54.f;
    
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    _notifications = [NSMutableArray array];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [self loadNotifications];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0]; // reset to 0
    if (self.notificationsDelegate && [self.notificationsDelegate respondsToSelector:@selector(setNotificationColor)]){
        [self.notificationsDelegate setNotificationColor];
    }
}

- (void)loadNotifications {
    [manager GET:@"notifications" parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success loading notifications: %@",responseObject);
        for (id dict in [responseObject objectForKey:@"notifications"]){
            Notification *notification = [Notification MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!notification){
                notification = [Notification MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [notification populateFromDictionary:dict];
            [_notifications addObject:notification];
        }
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load notifications: %@",error.description);
    }];
}

- (void)confirmDeletion {
    _notificationToDelete = _notifications[indexPathForDeletion.row];
    [[[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:@"Are you sure you want to delete this notificaiton?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]){
        [self deleteNotification];
    } else {
        _notificationToDelete = nil;
        indexPathForDeletion = nil;
    }
}

- (void)deleteNotification {
    [manager DELETE:[NSString stringWithFormat:@"notifications/%@",_notificationToDelete.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success deleting notification: %@",responseObject);
        
        [self.tableView beginUpdates];
        [_notifications removeObject:_notificationToDelete];
        [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
        // destroy all traces of that notification
        indexPathForDeletion = nil;
        [_notificationToDelete MR_deleteEntityInContext:[NSManagedObjectContext MR_defaultContext]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to delete notificaiton: %@",error.description);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationCell" forIndexPath:indexPath];
    Notification *notification = _notifications[indexPath.row];
    [cell configureForNotificaiton:notification];
    if (IDIOM != IPAD){
        [cell.textLabel setTextColor:[UIColor whiteColor]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.notificationsDelegate && [self.notificationsDelegate respondsToSelector:@selector(didSelectNotificationWithId:)]){
        Notification *notification = _notifications[indexPath.row];
        [self.notificationsDelegate didSelectNotificationWithId:notification.identifier];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (IDIOM == IPAD) ? 34 : 0;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGFloat headerHeight = IDIOM == IPAD ? 34.f : 0.f;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, headerHeight)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width-10, headerHeight)];
    [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [headerLabel setTextColor:[UIColor colorWithWhite:.5 alpha:.5]];
    [headerLabel setBackgroundColor:[UIColor clearColor]];
    [headerLabel setText:@"NOTIFICATIONS"];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
        [self confirmDeletion];
    } /*else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }*/
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
