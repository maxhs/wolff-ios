//
//  WFGroupsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/13/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFTablesViewController.h"
#import "WFTableCell.h"
#import "WFAppDelegate.h"

@interface WFTablesViewController () {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    CGFloat height;
    CGFloat width;
}

@end

@implementation WFTablesViewController
@synthesize lightTables = _lightTables;

-(id)initWithPanTarget:(id<WFLightTablesDelegate>)lightTableDelegate {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _lightTableDelegate = lightTableDelegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:0 alpha:.07]];
        self.tableView.rowHeight = 54.f;
    
    if (IDIOM == IPAD){
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
            width = screenWidth();
            height = screenHeight();
        } else {
            width = screenHeight();
            height = screenWidth();
        }
    }
    
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setUpFooter];
}

- (void)setUpFooter {
    UIView *footerContainerView = [[UIView alloc] initWithFrame:CGRectMake(10, height-64, self.view.frame.size.width-20, 64)];
    [footerContainerView setBackgroundColor:[UIColor colorWithWhite:.7 alpha:.7]];
    
    [self.view addSubview:footerContainerView];
}

- (void)loadLightTables {
    [manager GET:[NSString stringWithFormat:@"users/%@/light_tables",_currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success getting light tables: %@", responseObject);
        for (NSDictionary *dict in [responseObject objectForKey:@"light_tables"]){
            Table *lightTable = [Table MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!lightTable){
                lightTable = [Table MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [lightTable populateFromDictionary:dict];
            [_currentUser addLightTable:lightTable];
        }
        _lightTables = [NSMutableArray arrayWithArray:_currentUser.lightTables.array.mutableCopy];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error getting groups: %@",error.description);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _lightTables.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LightTableCell" forIndexPath:indexPath];
    [cell configureForTable:(Table*)_lightTables[indexPath.row]];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 34.f)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width, 34.f)];
    [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [headerLabel setTextColor:[UIColor colorWithWhite:.5 alpha:.5]];
    [headerLabel setText:@"SHARE ON LIGHT TABLE"];
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 34;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(lightTableSelected:)]){
        Table *lightTable = (Table*)_lightTables[indexPath.row];
        [self.lightTableDelegate lightTableSelected:lightTable.identifier];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
