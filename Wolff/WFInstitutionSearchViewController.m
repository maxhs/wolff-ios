//
//  WFInstitutionSearchViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFInstitutionSearchViewController.h"
#import "WFAppDelegate.h"
#import "Institution+helper.h"
#import "WFInstitutionSearchCell.h"

@interface WFInstitutionSearchViewController () {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    BOOL iOS8;
    User *_currentUser;
    CGFloat width;
    CGFloat height;
    NSMutableArray *_institutions;
    UIBarButtonItem *dismissButton;
}

@end

@implementation WFInstitutionSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    delegate = [UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    if (SYSTEM_VERSION >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
    } else {
        iOS8 = NO; height = screenWidth(); width = screenHeight();
    }
    _institutions = [NSMutableArray arrayWithArray:[Institution MR_findAll]];
    [self loadInstitutions];
    [self registerForKeyboardNotifications];
    
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackRemove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    [self.searchBar setPlaceholder:@"Search for your institution"];
    //reset the search bar font
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setTextColor:[UIColor blackColor]];
            [searchTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
            searchTextField.keyboardAppearance = UIKeyboardAppearanceDark;
            break;
        }
    }
    self.searchBar.delegate = self;
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    self.tableView.tableHeaderView = self.searchBar;
}

- (void)loadInstitutions {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [manager GET:[NSString stringWithFormat:@"institutions"] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        for (id dict in [responseObject objectForKey:@"institutions"]){
            Institution *institution = [Institution MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
            if (!institution){
                institution = [Institution MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [institution populateFromDictionary:dict];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self.tableView reloadData];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load institutions: %@",error.description);
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _institutions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFInstitutionSearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InstitutionCell"];
    [cell setBackgroundColor:[UIColor clearColor]];
    Institution *institution = _institutions[indexPath.row];
    [cell configureForInstitution:institution];

    if ([_currentUser.institutions containsObject:institution]){
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:searchBar.text forKey:@"search"];
    [manager GET:@"institutions" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success searching: %@",responseObject);
        for (id dict in [responseObject objectForKey:@"institutions"]){
            Institution *institution = [Institution MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
            if (!institution){
                institution = [Institution MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [institution populateFromDictionary:dict];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            _institutions = [Institution MR_findAll].mutableCopy;
            [self.tableView reloadData];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed searching for institutions: %@",error.description);
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Institution *institution = _institutions[indexPath.row];
    NSLog(@"Institution selected: %@",institution.name);
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(institutionSelected:)]){
        [self.searchDelegate institutionSelected:institution];
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

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self dismiss];
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note {
//    NSDictionary* info = [note userInfo];
//    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
//    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
//    NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
//    CGFloat keyboardHeight = keyboardValue.CGRectValue.size.height;
//    [UIView animateWithDuration:duration
//                          delay:0
//                        options:curve | UIViewAnimationOptionBeginFromCurrentState
//                     animations:^{
//                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
//                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
//                     }
//                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)note {
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         //self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                         //self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                     }
                     completion:nil];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
