//
//  WFSettingsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFAppDelegate.h"
#import "WFSettingsViewController.h"
#import "WFSettingsCell.h"
#import "Institution+helper.h"
#import "UIFontDescriptor+Custom.h"
#import "WFInstitutionSearchViewController.h"

@interface WFSettingsViewController () <UITextFieldDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UIBarButtonItem *doneEditingButton;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *saveButton;
    UITextField *emailTextField;
    UITextField *institutionTextField;
}

@end

@implementation WFSettingsViewController

@synthesize currentUser = _currentUser;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
    
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    [self loadUserDetails];
    
    _tableView.rowHeight = 54.f;
    [_tableView setBackgroundColor:[UIColor darkGrayColor]];
    [self registerForKeyboardNotifications];
    [self setUpNavigationButtons];
}

- (void)setUpNavigationButtons {
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackRemove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    [_logoutButton setTitle:@"LOG OUT" forState:UIControlStateNormal];
    [_logoutButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [_logoutButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
    [_logoutButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_logoutButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
    //_logoutButton.layer.borderColor = [UIColor colorWithWhite:.77 alpha:1].CGColor;
    //_logoutButton.layer.borderWidth = .5f;
    _logoutButton.layer.cornerRadius = 14.f;
    
    [_versionLabel setText:[NSString stringWithFormat:@"Version: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
    [_versionLabel setTextColor:[UIColor lightGrayColor]];
    [_versionLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    
    self.tableView.tableFooterView = _footerContainerView;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section {
    return 44.f;
}

- (void)loadUserDetails {
    [manager GET:[NSString stringWithFormat:@"%@/users/%@/edit",kApiBaseUrl,_currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success getting user details: %@",responseObject);
        
        [_currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
        [self.tableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get user details: %@",error.description);
    }];
}

- (void)saveSettings {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 5;
            break;
        case 1:
            return 3;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WFSettingsCell *cell = (WFSettingsCell *)[tableView dequeueReusableCellWithIdentifier:@"SettingsCell"];
    [cell.textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [cell.textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    
    if (indexPath.section == 0){
        [cell.settingsSwitch setHidden:YES];
        [cell.textField setHidden:NO];
        switch (indexPath.row) {
            case 0:
                [cell.textField setText:_currentUser.firstName];
                [cell.textField setPlaceholder:@"First name"];
                break;
            case 1:
                [cell.textField setText:_currentUser.lastName];
                [cell.textField setPlaceholder:@"Last name"];
                break;
            case 2:
                [cell.textField setText:_currentUser.email];
                [cell.textField setPlaceholder:@"albrecht@durer.com"];
                break;
            case 3:
                [cell.textField setText:_currentUser.phone];
                [cell.textField setPlaceholder:@"555-555-5555"];
                break;
            case 4:
                [cell.textField setText:_currentUser.institution.name];
                [cell.textField setPlaceholder:@"Affiliated institution (if any)"];
                institutionTextField = cell.textField;
                break;
                
            default:
                break;
        }
        cell.accessoryView = nil;
        
    } else if (indexPath.section == 1) {
        [cell.settingsSwitch setHidden:NO];
        [cell.textField setHidden:YES];
        switch (indexPath.row) {
            case 0:
                //email
                [cell.textLabel setText:@"Email notifications"];
                [cell.settingsSwitch setOn:_currentUser.emailPermission.boolValue];
                break;
            case 1:
                //push
                [cell.textLabel setText:@"Push notifications"];
                [cell.settingsSwitch setOn:_currentUser.pushPermission.boolValue];
                break;
            case 2:
                //text
                [cell.textLabel setText:@"Wolff texts"];
                [cell.settingsSwitch setOn:_currentUser.textPermission.boolValue];
                break;
            default:
                break;
        }
        [cell.settingsSwitch setTag:indexPath.row];
        [cell.settingsSwitch addTarget:self action:@selector(switchSwitched:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = cell.settingsSwitch;
    }
    return cell;
}

- (void)switchSwitched:(UISwitch*)s {
    switch (s.tag) {
        case 0:
            //email
            [_currentUser setEmailPermission:[NSNumber numberWithBool:s.isOn]];
            break;
        case 1:
            //push
            [_currentUser setPushPermission:[NSNumber numberWithBool:s.isOn]];
            break;
        case 2:
            //text
            [_currentUser setTextPermission:[NSNumber numberWithBool:s.isOn]];
            break;
            
        default:
            break;
    }
}

- (void)showInstitutionSearch {
    WFInstitutionSearchViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"InstitutionSearch"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == institutionTextField){
        [textField resignFirstResponder];
        [self showInstitutionSearch];
        return;
    }
    if (!doneEditingButton) {
        doneEditingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    }
    
    self.navigationItem.rightBarButtonItem = doneEditingButton;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = saveButton;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    return YES;
}

- (void)doneEditing {
    [self.view endEditing:YES];
}

- (void)logout {
    [delegate logout];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
    CGFloat keyboardHeight = keyboardValue.CGRectValue.size.height;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                     }
                     completion:nil];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
