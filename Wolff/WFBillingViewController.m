//
//  WFBillingViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/17/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFBillingViewController.h"
#import "WFAppDelegate.h"
#import "WFBillingCell.h"
#import "WFCardViewController.h"

@interface WFBillingViewController () <WFCardDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    CGFloat topInset;
}

@end

@implementation WFBillingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor clearColor]];
    
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [backgroundToolbar setTranslucent:YES];
    [self.view addSubview:backgroundToolbar];
    [self.view sendSubviewToBack:backgroundToolbar];

    topInset = self.navigationController.navigationBar.frame.size.height;
    _tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
    [_tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.07]];
    
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    [self loadBillingInformation];
    
    self.title = @"Billing Information";
}

- (void)loadBillingInformation {
    if (_currentUser.mobileToken.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [parameters setObject:_currentUser.mobileToken forKey:@"mobile_token"];
        [manager GET:[NSString stringWithFormat:@"users/%@/billing",_currentUser.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success getting user information: %@",responseObject);
            [_currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [_tableView reloadData];
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get billing information: %@",error.description);
        }];
    } else {
        NSLog(@"User can't be authenticated for billing purposes.");
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //return 2;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return 1;
    } else {
        return _currentUser.cards.count + 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFBillingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BillingCell" forIndexPath:indexPath];
    [cell setBackgroundColor:[UIColor clearColor]];
    UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
    [selectedView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    cell.selectedBackgroundView = selectedView;
    [cell.textLabel setNumberOfLines: 0];
    
    if (indexPath.section == 0){
        if (_currentUser.customerPlan.length){
            [cell.textLabel setText:[NSString stringWithFormat:@"You are currently signed up for the \"%@\" billing plan.",_currentUser.customerPlan]];
            [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
        } else {
            [cell.textLabel setText:@"You aren't currently signed up for a billing plan.\n\nPlease either sign up as an individual or as part of a registered institution on wolffapp.com."];
            [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
        }
        
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    } else {
        
        if (indexPath.row == _currentUser.cards.count){
            [cell.textLabel setText:@"Add new card"];
            [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansItalic] size:0]];
            [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        } else {
            Card *card = _currentUser.cards[indexPath.row];
            [cell configureForCard:card];
            [cell.textLabel setTextAlignment:NSTextAlignmentLeft];
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        return 90.f;
    } else {
        return 54.f;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 34;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //CGFloat headerHeight = section == 0 ? 0 : 34 ;
    CGFloat headerHeight = 34;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, headerHeight)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width-10, headerHeight)];
    [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [headerLabel setTextColor:[UIColor colorWithWhite:1 alpha:.27]];
    switch (section) {
        case 0:
            [headerLabel setText:@"CURRENT BILLING PLAN"];
            break;
        case 1:
            [headerLabel setText:@"YOUR CARDS"];
            break;
            
        default:
            break;
    }
    
    [headerView addSubview:headerLabel];
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row == _currentUser.cards.count){
        //[self performSegueWithIdentifier:@"NewCard" sender:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)addedCardWithId:(NSNumber *)cardId {
    Card *card = [Card MR_findFirstByAttribute:@"identifier" withValue:cardId inContext:[NSManagedObjectContext MR_defaultContext]];
    [_currentUser addCard:card];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"just added new card: %@",card);
        [_tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"NewCard"]){
        WFCardViewController *vc = [segue destinationViewController];
        vc.cardDelegate = self;
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Card *card = _currentUser.cards[indexPath.row];
        [self deleteCard:card];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (void)deleteCard:(Card*)card {
    NSLog(@"should be deleting card: %@",card.last4);
    [_currentUser removeCard:card];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    [manager DELETE:[NSString stringWithFormat:@"cards/%@",card.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success deleting a card: %@",responseObject);
        if ([responseObject objectForKey:@"text"] && [[responseObject objectForKey:@"text"] isEqualToString:kNotAuthorized]){
            
        } else {
            [card MR_deleteEntityInContext:[NSManagedObjectContext MR_defaultContext]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to delete a card: %@",error.description);
        [card MR_deleteEntityInContext:[NSManagedObjectContext MR_defaultContext]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    }];
}

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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
