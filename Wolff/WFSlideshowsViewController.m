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

@interface WFSlideshowsViewController () <UIAlertViewDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    UIRefreshControl *refreshControl;
    BOOL loading;
    NSIndexPath *indexPathForDeletion;
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
            if (slideshow.title.length){
                [cell.textLabel setText:slideshow.title];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
            } else {
                [cell.textLabel setText:@"No name..."];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLightItalic] size:0]];
            }
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
        [self confirmDeletion];
    }
}

- (void)confirmDeletion {
    Slideshow *slideshow = _currentUser.slideshows[indexPathForDeletion.row];
    NSString *title = slideshow.title.length ? [NSString stringWithFormat:@"\"%@\"",slideshow.title] : @"this slideshow";
    [[[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:[NSString stringWithFormat:@"Are you sure you want to delete %@? This can NOT be undone.",title] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete",nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]){
        [self deleteSlideshow];
    } else {
        indexPathForDeletion = nil;
    }
}

- (void)deleteSlideshow {
    Slideshow *slideshow = _currentUser.slideshows[indexPathForDeletion.row];
    if (slideshow && ![slideshow.identifier isEqualToNumber:@0]){
        [manager DELETE:[NSString stringWithFormat:@"slideshows/%@",slideshow.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.tableView beginUpdates];
            [_currentUser removeSlideshow:slideshow];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
            
            [slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                
            }];
            NSLog(@"Success deleting this slideshow: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to delete this slideshow: %@",error.description);
        }];
    }
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
