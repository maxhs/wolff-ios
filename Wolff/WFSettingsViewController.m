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
#import "WFAlert.h"
#import "WFUtilities.h"
#import "Alternate+helper.h"

@interface WFSettingsViewController () <UITextFieldDelegate, UIPopoverControllerDelegate, WFInstitutionSearchDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UIBarButtonItem *doneEditingButton;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *saveButton;
    UITextField *emailTextField;
    UITextField *firstNameTextField;
    UITextField *lastNameTextField;
    UITextField *phoneTextField;
    UITextField *institutionTextField;
    NSString *password;
    NSString *confirmPassword;
    UITextField *passwordTextField;
    UITextField *confirmPasswordTextField;
    UITextField *alternateTextField;
    UITextField *locationTextField;
    UIImageView *navBarShadowView;
    BOOL editing;
    BOOL changingPassword;
    NSIndexPath *indexPathToRemoveInstitution;
    NSIndexPath *indexPathToDeleteAlternate;
}
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) AFHTTPRequestOperation *mainRequest;
@end

@implementation WFSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    [self loadUserDetails];
    
    _tableView.rowHeight = 54.f;
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [backgroundToolbar setTranslucent:YES];
    [_tableView setBackgroundView:backgroundToolbar];
    [self registerForKeyboardNotifications];
    [self setUpNavigationButtons];
    changingPassword = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)setUpNavigationButtons {
    dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveSettings)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    [_logoutButton setTitle:@"LOG OUT" forState:UIControlStateNormal];
    [_logoutButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [_logoutButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
    [_logoutButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_logoutButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
    _logoutButton.layer.cornerRadius = 14.f;
    
    [_versionLabel setText:[NSString stringWithFormat:@"Version: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
    [_versionLabel setTextColor:[UIColor lightGrayColor]];
    [_versionLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    self.tableView.tableFooterView = _footerContainerView;
}

- (void)loadUserDetails {
    self.mainRequest = [manager GET:[NSString stringWithFormat:@"%@/users/%@/edit",kApiBaseUrl,self.currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success getting user details: %@",responseObject);
        [self.currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.mainRequest && !self.mainRequest.isCancelled){
                [self.tableView reloadData];
            }
            self.mainRequest = nil;
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get user details: %@",error.description);
        self.mainRequest = nil;
    }];
}

- (void)saveSettings {
    BOOL passwordChanged = NO;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (passwordTextField.text.length && confirmPasswordTextField.text && [confirmPasswordTextField.text isEqualToString:passwordTextField.text]){
        [parameters setObject:passwordTextField.text forKey:@"password"];
        [parameters setObject:passwordTextField.text forKey:@"password_confirmation"];
        passwordChanged = YES;
    }
    password = @"";
    confirmPassword = @"";
    
    if (emailTextField.text.length && ![emailTextField.text isEqualToString:self.currentUser.email]){
        [parameters setObject:emailTextField.text forKey:@"email"];
    }
    if (locationTextField.text.length && ![locationTextField.text isEqualToString:self.currentUser.location]){
        [parameters setObject:locationTextField.text forKey:@"location"];
    }
    if (phoneTextField.text.length && ![phoneTextField.text isEqualToString:self.currentUser.phone]){
        [parameters setObject:phoneTextField.text forKey:@"phone"];
    }
    if (firstNameTextField.text.length && ![firstNameTextField.text isEqualToString:self.currentUser.firstName]){
        [parameters setObject:firstNameTextField.text forKey:@"first_name"];
    }
    if (lastNameTextField.text.length && ![lastNameTextField.text isEqualToString:self.currentUser.lastName]){
        [parameters setObject:lastNameTextField.text forKey:@"last_name"];
    }
    NSMutableArray *institutionIds = [NSMutableArray arrayWithCapacity:self.currentUser.institutions.count];
    for (Institution *institution in self.currentUser.institutions){
        [institutionIds addObject:institution.identifier];
    }
    [parameters setObject:institutionIds forKey:@"institution_ids"];
    
    [ProgressHUD show:@"Saving..."];
    [manager PATCH:[NSString stringWithFormat:@"users/%@",self.currentUser.identifier] parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success saving user settings: %@",responseObject);
        [self.currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (passwordChanged){
                [WFAlert show:@"You successfully changed your password and updated your settings." withTime:3.3f];
            } else {
                [WFAlert show:@"Settings saved" withTime:2.7f];
            }
            [ProgressHUD dismiss];
            changingPassword = NO;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to save user settings: %@",error.description);
        [ProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Uh oh" message:@"Something went wrong while trying to save your settings. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if (changingPassword){
                return 7;
            } else {
                return 6;
            }
            break;
        case 1:
            // manage billing
            return 1;
            break;
        case 2:
            return self.currentUser.institutions.count; // manage institutions
            break;
        case 3:
            // manage alternate contact info
            return self.currentUser.alternates.count + 1;
            break;
        case 4:
            return 3;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFSettingsCell *cell = (WFSettingsCell *)[tableView dequeueReusableCellWithIdentifier:@"SettingsCell"];
    
    if (IDIOM == IPAD){
        [cell setBackgroundColor:kTextFieldBackground];
    } else {
        [cell setBackgroundColor:[UIColor whiteColor]];
    }
    cell.textField.delegate = self;
    
    if (indexPath.section == 0){
        [cell.settingsSwitch setHidden:YES];
        [cell.textField setHidden:NO];
        switch (indexPath.row) {
            case 0:
                [cell.textField setText:self.currentUser.firstName];
                [cell.textField setPlaceholder:@"First name"];
                firstNameTextField = cell.textField;
                break;
            case 1:
                [cell.textField setText:self.currentUser.lastName];
                [cell.textField setPlaceholder:@"Last name"];
                lastNameTextField = cell.textField;
                break;
            case 2:
                [cell.textField setText:self.currentUser.email];
                [cell.textField setPlaceholder:@"albrecht@durer.com"];
                emailTextField = cell.textField;
                break;
            case 3:
                [cell.textField setText:self.currentUser.phone];
                [cell.textField setPlaceholder:@"555-555-5555"];
                phoneTextField = cell.textField;
                break;
            case 4:
                [cell.textField setText:self.currentUser.location];
                [cell.textField setPlaceholder:@"Your location (e.g. Berlin, New York City, Byzantium)"];
                locationTextField = cell.textField;
                break;
            case 5:
                [cell.textField setText:password];
                [cell.textField setPlaceholder:@"Your password (only required if changing)"];
                passwordTextField = cell.textField;
                [passwordTextField setSecureTextEntry:YES];
                break;
            case 6:
                [cell.textField setText:confirmPassword];
                [cell.textField setPlaceholder:@"Confirm the above new password by typing it again"];
                confirmPasswordTextField = cell.textField;
                [confirmPasswordTextField setSecureTextEntry:YES];
                break;

            default:
                break;
        }
        cell.accessoryView = nil;
    } else if (indexPath.section == 1) {
        [cell.textField setHidden:YES];
        [cell.textField setUserInteractionEnabled:NO];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        if (self.currentUser.customerPlan.length){
            [cell.textLabel setText:self.currentUser.customerPlan];
        } else {
            [cell.textLabel setText:@"Set up billing"];
            [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
        }
    } else if (indexPath.section == 2) {
        [cell.textField setHidden:NO];
        [cell.textField setUserInteractionEnabled:NO];
        if (indexPath.row == self.currentUser.institutions.count){
            [cell.textField setPlaceholder:@"Add an affiliated institution"];
        } else {
            Institution *institution = self.currentUser.institutions[indexPath.row];
            [cell.textField setText:institution.name];
        }
    } else if (indexPath.section == 3) {
        [cell.textField setHidden:NO];
        [cell.actionButton setHidden:NO];
        [cell.actionButton setTag:indexPath.row];
        if (indexPath.row == self.currentUser.alternates.count){
            alternateTextField = cell.textField;
            [cell.textField setPlaceholder:@"Alternate email address(es)"];
            [cell.actionButton setTitle:@"ADD" forState:UIControlStateNormal];
            [cell.actionButton addTarget:self action:@selector(createAlternate:) forControlEvents:UIControlEventTouchUpInside];
            [cell.actionButton setHidden:NO];
        } else {
            Alternate *alternate = self.currentUser.alternates[indexPath.row];
            [cell.textField setText:alternate.email];
            [cell.textField setKeyboardType:UIKeyboardTypeEmailAddress];
            [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
            [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
            [cell.actionButton setHidden:YES];
            //[cell.actionButton setTitle:@"SAVE" forState:UIControlStateNormal];
            //[cell.actionButton addTarget:self action:@selector(editAlternate:) forControlEvents:UIControlEventTouchUpInside];
        }
    } else if (indexPath.section == 4) {
        [cell.settingsSwitch setHidden:NO];
        [cell.textField setHidden:YES];
        switch (indexPath.row) {
            case 0:
                [cell.textLabel setText:@"Email notifications"];
                [cell.settingsSwitch setOn:self.currentUser.emailPermission.boolValue];
                break;
            case 1:
                [cell.textLabel setText:@"Push notifications"];
                [cell.settingsSwitch setOn:self.currentUser.pushPermission.boolValue];
                break;
            case 2:
                [cell.textLabel setText:@"Wölff texts"];
                [cell.settingsSwitch setOn:self.currentUser.textPermission.boolValue];
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
            [self.currentUser setEmailPermission:[NSNumber numberWithBool:s.isOn]];
            break;
        case 1:
            [self.currentUser setPushPermission:[NSNumber numberWithBool:s.isOn]];
            break;
        case 2:
            [self.currentUser setTextPermission:[NSNumber numberWithBool:s.isOn]];
            break;
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (section == 0) ? 0 : 34.f;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGFloat headerHeight = section == 0 ? 0 : 34 ;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, headerHeight)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width-10, headerHeight)];
    [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [headerLabel setTextColor:[UIColor colorWithWhite:1 alpha:.27]];
    switch (section) {
        case 1:
            [headerLabel setText:@"BILLING"];
            break;
        case 2:
            [headerLabel setText:@"YOUR AFFILIATED INSTITUTIONS"];
            break;
        case 3:
            [headerLabel setText:@"SECONDARY CONTACT INFORMATION"];
            break;
        default:
            break;
    }
    
    [headerView addSubview:headerLabel];
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1){
        [self performSegueWithIdentifier:@"Billing" sender:nil];
    } else if (indexPath.section == 2 && indexPath.row == self.currentUser.institutions.count){
        WFSettingsCell *cell = (WFSettingsCell*)[_tableView cellForRowAtIndexPath:indexPath];
        [self showInstitutionSearchFromRect:cell.frame];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
}

- (void)showInstitutionSearchFromRect:(CGRect)rect {
    [self doneEditing];
    if (IDIOM == IPAD){
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
        WFInstitutionSearchViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"InstitutionSearch"];
        vc.searchDelegate = self;
        vc.preferredContentSize = CGSizeMake(370, 500);
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        self.popover.delegate = self;
        [self.popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
    } else {
        WFInstitutionSearchViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"InstitutionSearch"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    }
}

- (void)institutionSelected:(Institution *)institution {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    if (institution){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [manager POST:[NSString stringWithFormat:@"institutions/%@/add_user",institution.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success creating institution user: %@",responseObject);
            [self.tableView beginUpdates];
            [institution addUser:self.currentUser];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
            [WFAlert show:[NSString stringWithFormat:@"You've been added to %@, pending administrator review and approval.", institution.name] withTime:3.3f];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure creating institution user: %@",error.description);
        }];
    }
}

- (void)createAlternate:(UIButton*)button {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    if (!alternateTextField.text.length){
        [WFAlert show:@"Please make sure you've entered a valid email address before trying to add alternate contact information." withTime:3.3f];
        return;
    } else {
        [parameters setObject:alternateTextField.text forKey:@"email"];
    }
    [ProgressHUD show:[NSString stringWithFormat:@"Adding \"%@\"",alternateTextField.text]];
    [manager POST:@"alternates" parameters:@{@"alternate":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating an alternate: %@", responseObject);
        Alternate *newAlternate = [Alternate MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
        [newAlternate populateFromDictionary:[responseObject objectForKey:@"alternate"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD dismiss];
            [self.tableView reloadData];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        [WFAlert show:@"Sorry, but something went wrong while trying to add this alternate. Please try agian soon." withTime:3.3f];
        NSLog(@"Failed to edit alterante: %@",error.description);
    }];
}

- (void)editAlternate:(UIButton*)button {
    Alternate *alternate;
    if (self.currentUser.alternates.count == button.tag){
        return;
    }
    alternate = self.currentUser.alternates[button.tag];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [manager PATCH:[NSString stringWithFormat:@"alternates/%@",alternate.identifier] parameters:@{@"alternate":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success editing alternate: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to edit alterante: %@",error.description);
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && indexPath.row != self.currentUser.institutions.count) {
        return YES;
    } else if (indexPath.section == 3 && indexPath.row != self.currentUser.alternates.count){
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete){
        if (indexPath.section == 2){
            indexPathToRemoveInstitution = indexPath;
            [self removeInstitution];
        } else if (indexPath.section == 3){
            indexPathToDeleteAlternate = indexPath;
            [self deleteAlternate];
        }
    }
}

- (void)removeInstitution {
    Institution *institution = self.currentUser.institutions[indexPathToRemoveInstitution.row];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    [manager DELETE:[NSString stringWithFormat:@"institutions/%@/remove_user",institution.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success removing an institution: %@",responseObject);
        [self.tableView beginUpdates];
        [self.currentUser removeInstitution:institution];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        [self.tableView deleteRowsAtIndexPaths:@[indexPathToRemoveInstitution] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to remove an institutiuon: %@",error.description);
    }];
}

- (void)deleteAlternate {
    Alternate *alternateForDeletion = self.currentUser.alternates[indexPathToDeleteAlternate.row];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    
    [manager DELETE:[NSString stringWithFormat:@"alternates/%@",alternateForDeletion.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success deleting an alternate: %@",responseObject);
        [self.tableView beginUpdates];
        [alternateForDeletion MR_deleteEntityInContext:[NSManagedObjectContext MR_defaultContext]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        [self.tableView deleteRowsAtIndexPaths:@[indexPathToDeleteAlternate] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to delete an alternate: %@",error.description);
    }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    editing = YES;
    NSIndexPath *scrollToIndexPath;
    if (textField == firstNameTextField){
        scrollToIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    } else if (textField == lastNameTextField){
        scrollToIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    } else if (textField == emailTextField){
        scrollToIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    } else if (textField == phoneTextField){
        scrollToIndexPath = [NSIndexPath indexPathForRow:3 inSection:0];
    }
    
    if (scrollToIndexPath){
        [self.tableView scrollToRowAtIndexPath:scrollToIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
    
    if (!doneEditingButton) {
        doneEditingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    }
    
    self.navigationItem.rightBarButtonItem = doneEditingButton;
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = saveButton;
    if (textField == passwordTextField){
        password = passwordTextField.text;
        if (passwordTextField.text.length > 4){
            if (!changingPassword){
                changingPassword = YES;
                [self.tableView beginUpdates];
                NSIndexPath *indexPathToAdd = [NSIndexPath indexPathForRow:6 inSection:0];
                [self.tableView insertRowsAtIndexPaths:@[indexPathToAdd] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
                [confirmPasswordTextField becomeFirstResponder];
            }
        } else {
            if (changingPassword){
                changingPassword = NO;
                [self.tableView beginUpdates];
                NSIndexPath *indexPathToRemove = [NSIndexPath indexPathForRow:6 inSection:0];
                [self.tableView deleteRowsAtIndexPaths:@[indexPathToRemove] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
            }
        }
    } else if (textField == confirmPasswordTextField) {
        confirmPassword = confirmPasswordTextField.text;
    }
}

- (void)doneEditing {
    editing = NO;
    [self.view endEditing:YES];
}

- (void)logout {
    [WFAlert show:kLogoutMessage withTime:3.3f];
    [delegate logout];
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(logout)]) {
        [self.settingsDelegate logout];
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
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
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameEndUserInfoKey];
    CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
    CGFloat keyboardHeight = convertedKeyboardFrame.size.height;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                     }
                     completion:NULL];
}

- (void)keyboardWillHide:(NSNotification *)note {
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
                     completion:^(BOOL finished) {
    
                     }];
}

- (void)dismiss {
    if (editing){
        [self doneEditing];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.mainRequest cancel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
