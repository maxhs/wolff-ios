//
//  WFLightTablesViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/13/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFLightTablesViewController.h"
#import "WFTableCell.h"
#import "WFAppDelegate.h"
#import "WFUtilities.h"

@interface WFLightTablesViewController () {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat height;
    CGFloat width;
    UIImageView *navBarShadowView;
}
@property (strong, nonatomic) User *currentUser;
@end

@implementation WFLightTablesViewController

-(id)initWithPanTarget:(id<WFLightTablesDelegate>)lightTableDelegate {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _lightTableDelegate = lightTableDelegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    self.currentUser = [delegate.currentUser MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:0 alpha:.07]];
    self.tableView.rowHeight = 54.f;
    
    NSSortDescriptor *alphabeticalTableSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    _lightTables = self.currentUser.ownedTables.array.mutableCopy;
    [_lightTables sortUsingDescriptors:[NSArray arrayWithObject:alphabeticalTableSort]];
    [_lightTables enumerateObjectsUsingBlock:^(LightTable *lightTable, NSUInteger idx, BOOL *stop) {
        if ([lightTable.identifier isEqualToNumber:@0]){
            [lightTable MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        }
    }];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    if (IDIOM == IPAD){
        [self.view setBackgroundColor:[UIColor clearColor]];
        [self.tableView setBackgroundColor:[UIColor clearColor]];
        if (SYSTEM_VERSION >= 8.f){
            width = screenWidth(); height = screenHeight();
        } else {
            width = screenHeight(); height = screenWidth();
        }
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"left"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
        self.navigationItem.leftBarButtonItem = backButton;
    } else {
        [self.view setBackgroundColor:[UIColor clearColor]];
        [self.tableView setBackgroundColor:[UIColor clearColor]];
        UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
        [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
        backgroundToolbar.translucent = YES;
        [self.tableView setBackgroundView:backgroundToolbar];
        
        width = screenWidth(); height = screenHeight();
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        if (self.navigationController.viewControllers.count <= 1){
            UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
            self.navigationItem.leftBarButtonItem = dismissButton;
        }
    }
    
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    self.title = @"Your Light Tables";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
    [self loadLightTables];
    
    if (_slideshowShareMode){
        [self setPreferredContentSize:CGSizeMake(420, (54.f*_lightTables.count)+34.f)];
    } else {
        [self setPreferredContentSize:CGSizeMake(420, 54.f*(_lightTables.count+1))];
    }
}

- (void)loadLightTables {
    [manager GET:[NSString stringWithFormat:@"users/%@/light_tables",self.currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success getting light tables: %@", responseObject);
        for (id dict in [responseObject objectForKey:@"light_tables"]){
            if ([dict isKindOfClass:[NSDictionary class]]){
                LightTable *lightTable = [LightTable MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!lightTable){
                    lightTable = [LightTable MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [lightTable populateFromDictionary:dict];
                [self.currentUser addLightTable:lightTable];
            }
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self.tableView reloadData];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error getting groups: %@",error.description);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSSortDescriptor *alphabeticalTableSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    _lightTables = self.currentUser.ownedTables.array.mutableCopy;
    [_lightTables sortUsingDescriptors:[NSArray arrayWithObject:alphabeticalTableSort]];
    if (_slideshowShareMode){
        [self setPreferredContentSize:CGSizeMake(420, (54.f*_lightTables.count)+34.f)];
        return 1;
    } else {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && !_slideshowShareMode){
        return 1;
    } else {
        return _lightTables.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LightTableCell" forIndexPath:indexPath];
    UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
    [selectedView setBackgroundColor:[UIColor colorWithWhite:0 alpha:.14]];
    cell.selectedBackgroundView = selectedView;
    
    if (indexPath.section == 0 && !_slideshowShareMode){
        if (indexPath.row == 0){
            if (IDIOM == IPAD){
                [cell.imageView setImage:[UIImage imageNamed:@"plus"]];
            } else {
                [cell.imageView setImage:[UIImage imageNamed:@"whitePlus"]];
            }
            [cell.textLabel setText:@"New Table"];
        } else {
            [cell.imageView setImage:[UIImage imageNamed:@"favorite"]];
            [cell.textLabel setText:@"My Favorites"];
        }
    } else {
        LightTable *table = (LightTable*)_lightTables[indexPath.row];
        [cell configureForTable:table];
        if (_slideshow){
            if ([_slideshow.tables containsObject:table]){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        } else if (_photo){
            if ([table.photos containsObject:_photo]){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 34.f)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 34.f)];
    [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [headerLabel setTextColor:IDIOM == IPAD ? [UIColor colorWithWhite:.5 alpha:.5] : [UIColor whiteColor]];
    [headerLabel setText:@"TAP TO SHARE"];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (_slideshowShareMode){
        return 34;
    } else {
        return 0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && !_slideshowShareMode){
        if (indexPath.row == 0){
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(newLightTable)]){
                [self.lightTableDelegate newLightTable];
            }
        } else {
            [self favorite];
        }
    } else {
        LightTable *lightTable = (LightTable*)_lightTables[indexPath.row];
        if (_slideshow && [_slideshow.tables containsObject:lightTable]){
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(lightTableDeselected:)]){
                [self.lightTableDelegate lightTableDeselected:lightTable];
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        } else {
            if (_photo && [lightTable.photos containsObject:_photo]){
                if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(undropPhotoFromLightTable:)]){
                    [self.lightTableDelegate undropPhotoFromLightTable:lightTable];
                    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                }
            } else if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(lightTableSelected:)]){
                [self.lightTableDelegate lightTableSelected:lightTable];
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)favorite {
    if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(batchFavorite)]){
        [self.lightTableDelegate batchFavorite];
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


- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
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
