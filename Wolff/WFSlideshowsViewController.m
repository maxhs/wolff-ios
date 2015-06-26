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
    UIRefreshControl *refreshControl;
    BOOL loading;
    NSIndexPath *indexPathForDeletion;
    NSMutableOrderedSet *lightTables;
}
@property (strong, nonatomic) User *currentUser;
@end

@implementation WFSlideshowsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    self.currentUser = [delegate.currentUser MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    lightTables = [NSMutableOrderedSet orderedSet];
    [self loadSlideshows];
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:refreshControl];
    
    _tableView.rowHeight = 54.f;
    [_tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.1]];
    [_tableView setBackgroundColor:[UIColor clearColor]];
    [self.view setBackgroundColor:[UIColor clearColor]];
    self.title = @"Your Slideshows";

    if (IDIOM != IPAD){
        UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
        [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
        [backgroundToolbar setTranslucent:YES];
        [self.tableView setBackgroundView:backgroundToolbar];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGFloat contentSizeHeight = self.currentUser.slideshows.count ? 54.f*(self.currentUser.slideshows.count+1) : 54.f * 2;
    [self setPreferredContentSize:CGSizeMake(420, contentSizeHeight)];
}

- (void)handleRefresh {
    [ProgressHUD show:@"Refreshing..."];
    [self loadSlideshows];
}

- (void)loadSlideshows {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"users/%@/slideshows",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success getting slideshows: %@",responseObject);
        [self.currentUser populateFromDictionary:responseObject];
        [self endLoading];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get slideshows");
        [self endLoading];
    }];
}

- (void)endLoading {
    [self organizeSlideshowsByTable];
    loading = NO;
    [self.tableView reloadData];
    [ProgressHUD dismiss];
    if (refreshControl.isRefreshing){
        [refreshControl endRefreshing];
    }
}

- (void)organizeSlideshowsByTable {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return lightTables.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return 1;
    } else {
        if (!loading && self.currentUser.slideshows.count == 0){
            return 1;
            [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        } else {
            [tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
            LightTable *lightTable = lightTables[section+1];
            return lightTable.slideshows.count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFSlideshowCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SlideshowCell" forIndexPath:indexPath];
    UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
    [selectedView setBackgroundColor:[UIColor colorWithWhite:0 alpha:.14]];
    cell.selectedBackgroundView = selectedView;
    
    if (indexPath.section == 0){
        if (IDIOM == IPAD){
            [cell.imageView setImage:[UIImage imageNamed:@"plus"]];
        } else {
            [cell.imageView setImage:[UIImage imageNamed:@"whitePlus"]];
        }
        [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
        [cell.textLabel setText:@"New Slideshow"];
        [cell.textLabel setTextAlignment:NSTextAlignmentLeft];
    } else {
        [cell.imageView setImage:nil];
        LightTable *lightTable = lightTables[indexPath.section+1];
        
        if (!loading && lightTable.slideshows.count == 0){
            [cell.textLabel setText:@"No Slideshows"];
            [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
            [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
        } else {
            Slideshow *slideshow = self.currentUser.slideshows[indexPath.row];
            [cell.textLabel setTextAlignment:NSTextAlignmentLeft];
            if (slideshow.title.length){
                [cell.textLabel setText:slideshow.title];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
            } else {
                [cell.textLabel setText:@"No name..."];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLightItalic] size:0]];
            }
        }
    }
    
    [cell.textLabel setTextColor:(IDIOM == IPAD) ? [UIColor blackColor] : [UIColor whiteColor]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        if (self.slideshowsDelegate && [self.slideshowsDelegate respondsToSelector:@selector(newSlideshow)]) {
            [self.slideshowsDelegate newSlideshow];
        }
    } else {
        if (self.slideshowsDelegate && [self.slideshowsDelegate respondsToSelector:@selector(slideshowSelected:)]) {
            Slideshow *slideshow = self.currentUser.slideshows[indexPath.row];
            [self.slideshowsDelegate slideshowSelected:slideshow];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
        [self confirmDeletion];
    }
}

- (void)confirmDeletion {
    Slideshow *slideshow = self.currentUser.slideshows[indexPathForDeletion.row];
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
    Slideshow *slideshow = self.currentUser.slideshows[indexPathForDeletion.row];
    NSLog(@"Slideshow we're about to delete: %@",slideshow);
    if (slideshow && ![slideshow.identifier isEqualToNumber:@0]){
        [manager DELETE:[NSString stringWithFormat:@"slideshows/%@",slideshow.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.tableView beginUpdates];
            [self.currentUser removeSlideshow:slideshow];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
            
            [slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                
            }];
            NSLog(@"Success deleting this slideshow from slideshows tableView: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to delete this slideshow: %@",error.description);
        }];
    } else {
        [self.tableView beginUpdates];
        [self.currentUser removeSlideshow:slideshow];
        [slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0){
        return 0;
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
    [super didReceiveMemoryWarning]; // Dispose of any resources that can be recreated.
}

@end
