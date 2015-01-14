//
//  WFLightTableDetailsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFLightTableDetailsViewController.h"
#import "WFAppDelegate.h"
#import "WFLightTableDetailsCell.h"
#import "WFUtilities.h"
#import "Art+helper.h"
#import "Photo+helper.h"
#import "WFAlert.h"
#import "WFLightTableKeyCell.h"

#define kLightTableDescriptionPlaceholder @"Describe your light table..."

@interface WFLightTableDetailsViewController () < UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate> {
    BOOL iOS8;
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    UITextField *joinTableTextField;
    UITextField *titleTextField;
    UITextField *tableKeyTextField;
    UITextField *confirmTableKeyTextField;
    UITextView *descriptionTextView;
    UIBarButtonItem *dismissBarButton;
    UIImageView *navBarShadowView;
    Table *_table;
    CGFloat topInset;
}

@end

@implementation WFLightTableDetailsViewController
@synthesize photos = _photos;

- (void)viewDidLoad {
    [super viewDidLoad];
    if (SYSTEM_VERSION >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
    }
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
    UIToolbar *backgroundView = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [backgroundView setTranslucent:YES];
    [backgroundView setBarStyle:UIBarStyleBlackTranslucent];
    [self.tableView setBackgroundView:backgroundView];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.03]];
//    topInset = 200.f;
//    self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
    
    dismissBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissBarButton;
    dismissBarButton.tintColor = [UIColor blackColor];
    [_dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    self.title = @"New Light Table";
    
    if (!_tableId || [_tableId isEqualToNumber:@0]){
        _table = [Table MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    } else {
        _table = [Table MR_findFirstByAttribute:@"identifier" withValue:_tableId inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    if (!_table){
        // TO DO find table from the internet
    }
    
    if (_photos.count){
        NSLog(@"Should be pre-seeding table with %lu image objects",(unsigned long)_photos.count);
    }
    [self registerForKeyboardNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
    [self setUpFooterView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [titleTextField becomeFirstResponder];
}


- (void)setUpFooterView {
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 120)];
    [footerView setBackgroundColor:[UIColor clearColor]];
    
    CGFloat originX = 20;
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(originX, 7, self.view.frame.size.width-(originX*2), 37)];
    [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [headerLabel setTextColor:[UIColor colorWithWhite:.7 alpha:.7]];
    [headerLabel setText:@"The table key is like a password for your light table. Invite others to your light table by sharing this key."];
    headerLabel.numberOfLines = 0;
    [footerView addSubview:headerLabel];
    
    UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [submitButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [submitButton setTitle:@"CREATE" forState:UIControlStateNormal];
    [submitButton addTarget:self action:@selector(createLightTable) forControlEvents:UIControlEventTouchUpInside];
    
    [submitButton setFrame:CGRectMake(width*.1, headerLabel.frame.origin.y + headerLabel.frame.size.height+17, width*.6, 44)];
    [submitButton setBackgroundColor:[UIColor blackColor]];
    submitButton.layer.cornerRadius = 14.f;
    submitButton.clipsToBounds = YES;
    
    [footerView addSubview:submitButton];
    
    self.tableView.tableFooterView = footerView;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_showKey){
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && _showKey){
        return 1;
    } else {
        return 4;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && _showKey){
        WFLightTableKeyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LightTableKeyCell" forIndexPath:indexPath];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell.label setText:@"TABLE KEY"];
        
        [cell.textField setPlaceholder:@"The key code for the light table code you'd like to join"];
        [cell.joinButton setTitle:@"JOIN" forState:UIControlStateNormal];
        [cell.joinButton setUserInteractionEnabled:YES];
        [cell.joinButton addTarget:self action:@selector(joinLightTable) forControlEvents:UIControlEventTouchUpInside];
        CGFloat originY = cell.textField.frame.origin.y + cell.textField.frame.size.height + 14.f;
        [cell.joinButton setFrame:CGRectMake(width*.1, originY, width*.6, 44)];
        joinTableTextField = cell.textField;
        return cell;
    } else {
        WFLightTableDetailsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LightTableDetailsCell" forIndexPath:indexPath];
        if (!iOS8){
            [cell setBackgroundColor:[UIColor clearColor]];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        cell.textField.delegate = self;
        switch (indexPath.row) {
            case 0:
                [cell.label setText:@"TITLE"];
                titleTextField = cell.textField;
                [cell.textField setPlaceholder:@"e.g. Mesopotamian Pots"];
                [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                [cell.textField setReturnKeyType:UIReturnKeyNext];
                break;
            case 1:
            {
                [cell.label setText:@"DESCRIPTION"];
                [cell.textView setHidden:NO];
                [cell.textField setHidden:YES];
                descriptionTextView = cell.textView;
                if (_table && _table.tableDescription.length){
                    [cell.textView setText:_table.tableDescription];
                    [cell.textView setTextColor:[UIColor blackColor]];
                } else {
                    [cell.textView setText:kLightTableDescriptionPlaceholder];
                    [cell.textView setTextColor:kPlaceholderTextColor];
                }
                cell.textView.delegate = self;
                [cell.textView setReturnKeyType:UIReturnKeyNext];
            }
                break;
            case 2:
                [cell.label setText:@"TABLE KEY"];
                tableKeyTextField = cell.textField;
                [cell.textField setPlaceholder:@"Your light table key"];
                [cell.textField setReturnKeyType:UIReturnKeyNext];
                break;
            case 3:
                confirmTableKeyTextField = cell.textField;
                [cell.textField setPlaceholder:@"Confirm table key"];
                [cell.textField setReturnKeyType:UIReturnKeyGo];
                break;
                
            default:
                break;
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && _showKey){
        return 140;
    } else {
        if (indexPath.row == 1){
            return 88;
        } else {
            return 44;
        }
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 34)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width-10, 34)];
    [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [headerLabel setTextColor:[UIColor colorWithWhite:1 alpha:.27]];
    if (section == 0 && _showKey){
        [headerLabel setText:@"JOIN A LIGHT TABLE"];
    } else {
        [headerLabel setText:@"LIGHT TABLE DETAILS"];
    }
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (void)createLightTable {
    [self.view endEditing:YES];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (titleTextField.text.length){
        [parameters setObject:titleTextField.text forKey:@"name"];
    } else {
        [WFAlert show:@"Please make sure you've included a name for your light table before continuing." withTime:3.3f];
        return;
    }
    if (descriptionTextView.text.length){
        [parameters setObject:descriptionTextView.text forKey:@"description"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"owner_id"];
    }
    if (tableKeyTextField.text.length){
        if ([tableKeyTextField.text isEqualToString:confirmTableKeyTextField.text]){
            [parameters setObject:tableKeyTextField.text forKey:@"code"];
        } else {
            [WFAlert show:@"Please ensure that your light table keys match before continuing." withTime:3.3f];
            return;
        }
    } else {
        [WFAlert show:@"Please ensure you've added a light table key before continuing." withTime:3.3f];
        return;
    }
    NSMutableArray *photoIds = [NSMutableArray arrayWithCapacity:_photos.count];
    for (Photo *photo in _photos){
        [photoIds addObject:photo.identifier];
    }
    [parameters setObject:photoIds forKey:@"photo_ids"];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_ids"];
    [ProgressHUD show:@"Creating light table..."];
    [manager POST:@"light_tables" parameters:@{@"light_table":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a light table: %@", responseObject);
        [_table populateFromDictionary:[responseObject objectForKey:@"light_table"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [WFAlert show:[NSString stringWithFormat:@"\"%@\" successfully created!",_table.name] withTime:2.7f];
            [self dismiss];
            [ProgressHUD dismiss];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        if ([operation.responseString isEqualToString:kExistingLightTable]){
            [WFAlert show:@"There's already a light table using that key code. Please choose another."  withTime:3.3f];
        } else {
            NSLog(@"Error creating a light table: %@",error.description);
        }
    }];
}

- (void)joinLightTable {
    [self.view endEditing:YES];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (joinTableTextField.text.length){
        [parameters setObject:joinTableTextField.text forKey:@"code"];
    } else {
        [WFAlert show:@"Please make sure you've entered a valid key before attempting to join a light table" withTime:3.3f];
        return;
    }
    if (_table && ![_table.identifier isEqualToNumber:@0]) {
        [parameters setObject:_table.identifier forKey:@"id"];
    }
    
    [manager POST:@"light_tables/join" parameters:@{@"light_table":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Response object for joining a light table: %@",responseObject);
        NSDictionary *lightTableDict = [responseObject objectForKey:@"light_table"];
        if (_table.identifier && [_table.identifier isEqualToNumber:[lightTableDict objectForKey:@"id"]]){
            [_table populateFromDictionary:lightTableDict];
        } else {
            _table = [Table MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [_table populateFromDictionary:lightTableDict];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [WFAlert show:[NSString stringWithFormat:@"You just joined \"%@\"",_table.name] withTime:3.3f];
            [self dismiss];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"operation response: %@",operation.responseString);
        if ([operation.responseString isEqualToString:kIncorrectLightTableCode]){
            [WFAlert show:@"We couldn't find a light table for that key."  withTime:3.3f];
        } else if ([operation.responseString isEqualToString:kNoLightTable]){
            [WFAlert show:@"We couldn't find a light table for that key."  withTime:3.3f];
        } else {
            NSLog(@"Error joining light table: %@",error.description);
        }
    }];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:kLightTableDescriptionPlaceholder]){
        [textView setText:@""];
        [textView setTextColor:[UIColor blackColor]];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (!textView.text.length){
        [textView setText:kLightTableDescriptionPlaceholder];
        [textView setTextColor:kPlaceholderTextColor];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        if (textField == titleTextField){
            [descriptionTextView becomeFirstResponder];
        } else if (textField == tableKeyTextField) {
            [confirmTableKeyTextField becomeFirstResponder];
        } else if (textField == confirmTableKeyTextField) {
            //[self connect];
        }
        return NO;
    } else {
        return YES;
    }
}

- (void)doneEditing {
    [self.view endEditing:YES];
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

- (void)registerForKeyboardNotifications
{
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
                     completion:nil];
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
