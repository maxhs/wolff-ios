//
//  WFSlideshowsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideshowsViewController.h"
#import "WFAppDelegate.h"
#import "WFSlideshowCell.h"

@interface WFSlideshowsViewController () {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    UIRefreshControl *refreshControl;
    BOOL loading;
}

@end

@implementation WFSlideshowsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    [self loadSlideshows];
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:refreshControl];
    
    [_tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.1]];
    [_tableView setBackgroundColor:[UIColor blackColor]];
}

- (void)handleRefresh {
    [ProgressHUD show:@"Refreshing..."];
    [self loadSlideshows];
}

- (void)loadSlideshows {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"users/%@/slideshows",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success getting slideshows: %@",responseObject);
        [_currentUser populateFromDictionary:responseObject];
        [self endLoading];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get slideshows");
        [self endLoading];
    }];
}

- (void)endLoading {
    loading = NO;
    [self.tableView reloadData];
    [ProgressHUD dismiss];
    if (refreshControl.isRefreshing){
        [refreshControl endRefreshing];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        if (!loading && _currentUser.slideshows.count == 0){
            return 1;
            [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        } else {
            [tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
            return _currentUser.slideshows.count;
        }
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFSlideshowCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SlideshowCell" forIndexPath:indexPath];
    if (indexPath.section == 0){
        [cell.imageView setImage:nil];
        if (!loading && _currentUser.slideshows.count == 0){
            [cell.textLabel setText:@"No Slideshows"];
            [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
        } else {
            Slideshow *slideshow = _currentUser.slideshows[indexPath.row];
            [cell.textLabel setText:slideshow.title];
        }
        
    } else {
        [cell.imageView setImage:[UIImage imageNamed:@"whitePlus"]];
        [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
        [cell.textLabel setText:@"New Slideshow"];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        if (indexPath.row < _currentUser.slideshows.count){
            if (self.slideshowDelegate && [self.slideshowDelegate respondsToSelector:@selector(slideshowSelected:)]) {
                Slideshow *slideshow = _currentUser.slideshows[indexPath.row];
                [self.slideshowDelegate slideshowSelected:slideshow];
            }
        }
    } else {
        if (self.slideshowDelegate && [self.slideshowDelegate respondsToSelector:@selector(newSlideshow)]) {
            [self.slideshowDelegate newSlideshow];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0){
        return 34;
    } else {
        return 0;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGFloat headerHeight = section == 0 ? 34 : 0 ;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, headerHeight)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width-10, 34)];
    [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [headerLabel setTextColor:[UIColor colorWithWhite:1 alpha:.27]];
    [headerLabel setText:@"SLIDESHOWS"];
    
    [headerView addSubview:headerLabel];

    return headerView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
