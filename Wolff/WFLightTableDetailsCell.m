//
//  WFLightTableDetailsCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFLightTableDetailsCell.h"
#import "Constants.h"
#import "WFLightTableTableCell.h"
#import "WFAppDelegate.h"
#import "WFAlert.h"
#import "Constants.h"

@interface WFLightTableDetailsCell () <UITextFieldDelegate, UITextViewDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UITextField *titleTextField;
    UITextField *tableKeyTextField;
    UITextField *confirmTableKeyTextField;
    UITextField *ownersTextField;
    UITextField *membersTextField;
    UITextView *descriptionTextView;
    CGFloat keyboardHeight;
}

@end

@implementation WFLightTableDetailsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self setBackgroundColor:[UIColor clearColor]];
    [_headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [_headerLabel setTextColor:[UIColor colorWithWhite:1 alpha:.9]];
    [_actionButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _actionButton.layer.cornerRadius = 14.f;
    _actionButton.clipsToBounds = YES;
    [_actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setShowsVerticalScrollIndicator:NO];
    [self registerForKeyboardNotifications];
}

- (void)configure{
    self.tableView.tableHeaderView = _topContainerView;
    [self.tableView reloadData];
    if (IDIOM == IPAD){
        if ([self.lightTable.identifier isEqualToNumber:@0]){
            [self.actionButton setTitle:@"CREATE" forState:UIControlStateNormal];
            [self.headerLabel setText:@"CREATE A LIGHT TABLE"];
        } else {
            [self.actionButton setTitle:@"SAVE" forState:UIControlStateNormal];
            if (self.lightTable.name.length){
                [self.headerLabel setText:self.lightTable.name];
            } else {
                [self.headerLabel setText:@"EDIT YOUR LIGHT TABLE"];
            }
        }
        [self.actionButton addTarget:self action:@selector(post) forControlEvents:UIControlEventTouchUpInside];
        [self.actionButton setUserInteractionEnabled:YES];
    } else {
        [self.actionButton setHidden:YES];
        [self.headerLabel setText:@""];
    }
}

- (void)startTypingTitle {
    [titleTextField becomeFirstResponder];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFLightTableTableCell *cell = (WFLightTableTableCell *)[tableView dequeueReusableCellWithIdentifier:@"LightTableCell"];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.textField setHidden:NO];
    [cell.textView setHidden:YES];
    switch (indexPath.row) {
        case 0:
            titleTextField = cell.textField;
            [titleTextField setPlaceholder:@"e.g. Mesopotamian Pots"];
            [cell.textField setText:self.lightTable.name];
            [cell.cellLabel setText:@"NAME"];
            titleTextField.delegate = self;
            [titleTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            [titleTextField setReturnKeyType:UIReturnKeyNext];
            break;
        case 1:
            descriptionTextView = cell.textView;
            descriptionTextView.delegate = self;
            [cell.cellLabel setText:@"DESCRIPTION"];
            [cell.textField setHidden:YES];
            
            if (self.lightTable && self.lightTable.tableDescription.length){
                [descriptionTextView setText:self.lightTable.tableDescription];
                [descriptionTextView setTextColor:[UIColor blackColor]];
            } else {
                [descriptionTextView setText:kLightTableDescriptionPlaceholder];
                [descriptionTextView setTextColor:[UIColor colorWithWhite:0 alpha:.23]];
            }
            
            [descriptionTextView setReturnKeyType:UIReturnKeyDefault];
            [cell.textView setHidden:NO];
            break;
        case 2:
            tableKeyTextField = cell.textField;
            [tableKeyTextField setText:self.lightTable.code];
            [tableKeyTextField setPlaceholder:@"Your light table key"];
            [tableKeyTextField setReturnKeyType:UIReturnKeyNext];
            tableKeyTextField.delegate = self;
            if (IDIOM == IPAD){
                [cell.cellLabel setText:@"TABLE KEY - THE PASSWORD REQUIRED TO JOIN THIS LIGHT TABLE"];
            } else {
                [cell.cellLabel setText:@"TABLE KEY - YOUR PASSWORD FOR THIS LIGHT TABLE"];
            }
            break;
        case 3:
            confirmTableKeyTextField = cell.textField;
            [confirmTableKeyTextField setText:self.lightTable.code];
            [confirmTableKeyTextField setPlaceholder:@"Confirm that your table key matches"];
            [confirmTableKeyTextField setReturnKeyType:UIReturnKeyGo];
            [cell.cellLabel setText:@"CONFIRM TABLE KEY"];
            confirmTableKeyTextField.delegate = self;
            break;
        case 4:
            ownersTextField = cell.textField;
            [ownersTextField setPlaceholder:@"Select who can manage this light table"];
            [cell.cellLabel setText:@"OWNERS"];
            if (self.lightTable.owners.count){
                [cell.textField setText:self.lightTable.ownersToSentence];
            } else {
                [cell.textField setText:@""];
            }
            ownersTextField.delegate = self;
            break;
        case 5:
            membersTextField = cell.textField;
            membersTextField.delegate = self;
            [membersTextField setPlaceholder:@"Add or remove light table members"];
            if (self.lightTable.users.count){
                [cell.textField setText:self.lightTable.membersToSentence];
            } else {
                [cell.textField setText:@""];
            }
            [cell.cellLabel setText:@"MEMBERS"];
            break;
            
        default:
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1){
        return 120.f;
    } else {
        return 60.f;
    }
}

- (void)post {
    if (self.lightTable){
        [self saveLightTable];
    } else {
        [self createLightTable];
    }
}

- (void)save {
    [self generateParameters];
}

- (NSMutableDictionary*)generateParameters {
    [self doneEditing];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if (titleTextField.text.length){
        [self.lightTable setName:titleTextField.text];
        [parameters setObject:titleTextField.text forKey:@"name"];
    }
    if (descriptionTextView.text.length && ![descriptionTextView.text isEqualToString:kLightTableDescriptionPlaceholder]){
        [self.lightTable setTableDescription:descriptionTextView.text];
        [parameters setObject:descriptionTextView.text forKey:@"description"];
    }
    if (descriptionTextView.text.length && ![descriptionTextView.text isEqualToString:kLightTableDescriptionPlaceholder]){
        [self.lightTable setTableDescription:descriptionTextView.text];
        [parameters setObject:descriptionTextView.text forKey:@"description"];
    }
    if (tableKeyTextField.text.length && [tableKeyTextField.text isEqualToString:confirmTableKeyTextField.text]){
        [parameters setObject:tableKeyTextField.text forKey:@"code"];
        [self.lightTable setCode:tableKeyTextField.text];
    }
    
    NSMutableArray *photoIds = [NSMutableArray arrayWithCapacity:_photos.count];
    for (Photo *photo in _photos){
        [photoIds addObject:photo.identifier];
        [self.lightTable addPhoto:photo];
    }
    [parameters setObject:photoIds forKey:@"photo_ids"];
    
    NSMutableArray *userIds = [NSMutableArray arrayWithCapacity:self.lightTable.users.count];
    [self.lightTable.users enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
        [userIds addObject:user.identifier];
    }];
    [parameters setObject:userIds forKey:@"user_ids"];
    
    NSMutableArray *ownerIds = [NSMutableArray arrayWithCapacity:self.lightTable.owners.count];
    [self.lightTable.owners enumerateObjectsUsingBlock:^(User *owner, NSUInteger idx, BOOL *stop) {
        [ownerIds addObject:owner.identifier];
    }];
    [parameters setObject:ownerIds forKey:@"owner_ids"];
    
    return parameters;
}

- (void)createLightTable {
    NSMutableDictionary *parameters = [self generateParameters];
    if (parameters == nil){
        return;
    }
    if (tableKeyTextField.text.length){
        if ([tableKeyTextField.text isEqualToString:confirmTableKeyTextField.text]){
            [parameters setObject:tableKeyTextField.text forKey:@"code"];
            [self.lightTable setCode:tableKeyTextField.text];
        } else {
            [WFAlert show:@"Please ensure that your light table keys match before continuing." withTime:3.3f];
            return;
        }
    } else {
        [WFAlert show:@"Please ensure you've added a light table key before continuing." withTime:3.3f];
        return;
    }
    if (!titleTextField.text.length){
        [WFAlert show:@"Please make sure you've included a name for your light table before continuing." withTime:3.3f];
        return;
    }
    [ProgressHUD show:[NSString stringWithFormat:@"Creating \"%@\"",titleTextField.text]];
    [manager POST:@"light_tables" parameters:@{@"light_table":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a light table: %@", responseObject);
        [self.lightTable populateFromDictionary:[responseObject objectForKey:@"light_table"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(didCreateLightTable:)]){
                [self.lightTableDelegate didCreateLightTable:self.lightTable];
            }
            [ProgressHUD dismiss];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        if ([operation.responseString isEqualToString:kExistingLightTable]){
            [WFAlert show:@"Sorry, but there's already another light table using that key code.\n\nPlease choose another."  withTime:3.3f];
        } else {
            NSLog(@"Error creating a light table: %@",error.description);
        }
    }];
}

- (void)saveLightTable {
    [self doneEditing];
    if ([self.lightTable.identifier isEqualToNumber:@0]){
        return [self createLightTable];
    }
    NSMutableDictionary *parameters = [self generateParameters];
    if (tableKeyTextField.text.length){
        if ([tableKeyTextField.text isEqualToString:confirmTableKeyTextField.text]){
            [parameters setObject:tableKeyTextField.text forKey:@"code"];
            [self.lightTable setCode:tableKeyTextField.text];
        } else {
            [WFAlert show:@"Please ensure that your light table keys match before continuing." withTime:3.3f];
            return;
        }
    } else {
        [WFAlert show:@"Please ensure you've added a light table key before continuing." withTime:3.3f];
        return;
    }
    if (!titleTextField.text.length){
        [WFAlert show:@"Please make sure you've included a name for your light table before continuing." withTime:3.3f];
        return;
    }
    
    [ProgressHUD show:@"Saving light table..."];
    [manager PATCH:[NSString stringWithFormat:@"light_tables/%@",self.lightTable.identifier] parameters:@{@"light_table":parameters,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success saving a light table: %@", responseObject);
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(didUpdateLightTable:)]){
                [self.lightTableDelegate didUpdateLightTable:self.lightTable];
            }
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        if ([operation.responseString isEqualToString:kExistingLightTable]){
            [WFAlert show:@"Sorry, but there's already another light table using that key code.\n\nPlease choose another."  withTime:3.3f];
        } else {
            NSLog(@"Error saving a light table: %@",error.description);
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
        [textView setTextColor:[UIColor colorWithWhite:0 alpha:.23]];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == ownersTextField){
        [textField resignFirstResponder];
        [self showOwners];
    } else if (textField == membersTextField){
        [textField resignFirstResponder];
        [self showMembers];
    }
}

- (void)showOwners {
    [self generateParameters];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(showOwners)]){
        [self.lightTableDelegate showOwners];
    }
}

- (void)showMembers {
    [self generateParameters];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(showMembers)]){
        [self.lightTableDelegate showMembers];
    }
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
            [self createLightTable];
        }
        return NO;
    } else {
        if (textField == confirmTableKeyTextField){
            NSString *newText = [confirmTableKeyTextField.text stringByReplacingCharactersInRange:range withString:string];
            if (titleTextField.text.length && [tableKeyTextField.text isEqualToString:newText]){
                [self.actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.33]];
                self.actionButton.enabled = YES;
            } else {
                [self.actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
                self.actionButton.enabled = NO;
            }
        } else if (textField == tableKeyTextField){
            NSString *newText = [tableKeyTextField.text stringByReplacingCharactersInRange:range withString:string];
            if (titleTextField.text.length && [confirmTableKeyTextField.text isEqualToString:newText]){
                [self.actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.33]];
                self.actionButton.enabled = YES;
            } else {
                [self.actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
                self.actionButton.enabled = NO;
            }
        } else if (textField == titleTextField){
            NSString *newText = [titleTextField.text stringByReplacingCharactersInRange:range withString:string];
            if (newText.length && ((tableKeyTextField.text.length && [confirmTableKeyTextField.text isEqualToString:tableKeyTextField.text]) || self.lightTable)){
                [self.actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.33]];
                self.actionButton.enabled = YES;
            } else {
                [self.actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
                self.actionButton.enabled = NO;
            }
        }
        return YES;
    }
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
    if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(keyboardUp)]){
        [self.lightTableDelegate keyboardUp];
    }
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameEndUserInfoKey];
    CGRect convertedKeyboardFrame = [self convertRect:keyboardValue.CGRectValue fromView:self.window];
    keyboardHeight = convertedKeyboardFrame.size.height;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight+20.f, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight+20.f, 0);
                     } completion:^(BOOL finished) {
                         
                     }];
}

- (void)keyboardWillHide:(NSNotification *)note {
    if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(keyboardDown)]){
        [self.lightTableDelegate keyboardDown];
    }
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameEndUserInfoKey];
    CGRect convertedKeyboardFrame = [self convertRect:keyboardValue.CGRectValue fromView:self.window];
    keyboardHeight = convertedKeyboardFrame.size.height;
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                     } completion:nil];
}

- (void)doneEditing {
    [self.contentView endEditing:YES];
}

@end
