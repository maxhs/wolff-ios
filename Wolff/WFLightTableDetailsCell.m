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
    LightTable *_lightTable;
    UITextField *titleTextField;
    UITextField *tableKeyTextField;
    UITextField *confirmTableKeyTextField;
    UITextField *ownersTextField;
    UITextField *membersTextField;
    UITextView *descriptionTextView;
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
}

- (void)configureForLightTable:(LightTable *)lightTable{
    self.tableView.tableHeaderView = _topContainerView;
    [self.tableView reloadData];
    if (lightTable){
        _lightTable = lightTable;
        [self.headerLabel setText:lightTable.name];
    }
    
    if ([_lightTable.identifier isEqualToNumber:@0]){
        [self.actionButton setTitle:@"CREATE" forState:UIControlStateNormal];
    } else {
        [self.actionButton setTitle:@"SAVE" forState:UIControlStateNormal];
    }
    
    [self.actionButton addTarget:self action:@selector(post) forControlEvents:UIControlEventTouchUpInside];
    [self.actionButton setUserInteractionEnabled:YES];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([_lightTable.identifier isEqualToNumber:@0]){
        return 4;
    } else {
        return 6;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFLightTableTableCell *cell = (WFLightTableTableCell *)[tableView dequeueReusableCellWithIdentifier:@"LightTableCell"];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.textField setHidden:NO];
    [cell.textView setHidden:YES];
    switch (indexPath.row) {
        case 0:
            titleTextField = cell.textField;
            [titleTextField setPlaceholder:@"e.g. Mesopotamian Pots"];
            [cell.textField setText:_lightTable.name];
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
            
            if (_lightTable && _lightTable.tableDescription.length){
                [descriptionTextView setText:_lightTable.tableDescription];
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
            [tableKeyTextField setPlaceholder:@"Your light table key"];
            [tableKeyTextField setReturnKeyType:UIReturnKeyNext];
            tableKeyTextField.delegate = self;
            [cell.cellLabel setText:@"TABLE KEY - THE PASSWORD REQUIRED TO JOIN THIS LIGHT TABLE"];
            break;
        case 3:
            confirmTableKeyTextField = cell.textField;
            [confirmTableKeyTextField setPlaceholder:@"Confirm that your table key matches"];
            [confirmTableKeyTextField setReturnKeyType:UIReturnKeyGo];
            [cell.cellLabel setText:@"CONFIRM TABLE KEY"];
            confirmTableKeyTextField.delegate = self;
            break;
        case 4:
            ownersTextField = cell.textField;
            [ownersTextField setPlaceholder:@"Select who can manage this light table"];
            [cell.cellLabel setText:@"OWNERS"];
            if (_lightTable.owners.count){
                [cell.textField setText:_lightTable.ownersToSentence];
            } else {
                [cell.textField setText:@""];
            }
            ownersTextField.delegate = self;
            break;
        case 5:
            membersTextField = cell.textField;
            membersTextField.delegate = self;
            [membersTextField setPlaceholder:@"Add or remove light table members"];
            if (_lightTable.users.count){
                [cell.textField setText:_lightTable.membersToSentence];
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
    if (_lightTable){
        [self saveLightTable];
    } else {
        [self createLightTable];
    }
}

- (NSMutableDictionary*)generateParameters {
    [self doneEditing];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (tableKeyTextField.text.length){
        if ([tableKeyTextField.text isEqualToString:confirmTableKeyTextField.text]){
            [parameters setObject:tableKeyTextField.text forKey:@"code"];
        } else {
            [WFAlert show:@"Please ensure that your light table keys match before continuing." withTime:3.3f];
            return nil;
        }
    } else {
        [WFAlert show:@"Please ensure you've added a light table key before continuing." withTime:3.3f];
        return nil;
    }
    
    if (titleTextField.text.length){
        [parameters setObject:titleTextField.text forKey:@"name"];
    } else {
        [WFAlert show:@"Please make sure you've included a name for your light table before continuing." withTime:3.3f];
        return nil;
    }
    if (descriptionTextView.text.length && ![descriptionTextView.text isEqualToString:kLightTableDescriptionPlaceholder]){
        [parameters setObject:descriptionTextView.text forKey:@"description"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"owner_id"];
    }
    
    NSMutableArray *photoIds = [NSMutableArray arrayWithCapacity:_photos.count];
    for (Photo *photo in _photos){
        [photoIds addObject:photo.identifier];
    }
    [parameters setObject:photoIds forKey:@"photo_ids"];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_ids"];
    return parameters;
}

- (void)createLightTable {
    NSMutableDictionary *parameters = [self generateParameters];
    if (parameters == nil){
        return;
    }
    [ProgressHUD show:[NSString stringWithFormat:@"Creating \"%@\"",titleTextField.text]];
    [manager POST:@"light_tables" parameters:@{@"light_table":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a light table: %@", responseObject);
        [_lightTable populateFromDictionary:[responseObject objectForKey:@"light_table"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(didCreateLightTable:)]){
                [self.lightTableDelegate didCreateLightTable:_lightTable];
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
    if ([_lightTable.identifier isEqualToNumber:@0]){
        return [self createLightTable];
    }
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (titleTextField.text.length){
        [parameters setObject:titleTextField.text forKey:@"name"];
        [_lightTable setName:titleTextField.text];
    } else {
        [WFAlert show:@"Please make sure you've included a name for your light table before continuing." withTime:3.3f];
        return;
    }
    if (descriptionTextView.text.length && ![descriptionTextView.text isEqualToString:kLightTableDescriptionPlaceholder]){
        [_lightTable setTableDescription:descriptionTextView.text];
        [parameters setObject:descriptionTextView.text forKey:@"description"];
    } else {
        [parameters setObject:@"" forKey:@"description"];
    }
    if (tableKeyTextField.text.length && [tableKeyTextField.text isEqualToString:confirmTableKeyTextField.text]){
        [_lightTable setCode:tableKeyTextField.text];
        [parameters setObject:tableKeyTextField.text forKey:@"code"];
    }
    
    NSMutableArray *userIds = [NSMutableArray arrayWithCapacity:_lightTable.users.count];
    [_lightTable.users enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
        [userIds addObject:user.identifier];
    }];
    [parameters setObject:userIds forKey:@"user_ids"];
    
    NSMutableArray *ownerIds = [NSMutableArray arrayWithCapacity:_lightTable.owners.count];
    [_lightTable.owners enumerateObjectsUsingBlock:^(User *owner, NSUInteger idx, BOOL *stop) {
        [ownerIds addObject:owner.identifier];
    }];
    [parameters setObject:ownerIds forKey:@"owner_ids"];
    
    [ProgressHUD show:@"Saving light table..."];
    [manager PATCH:[NSString stringWithFormat:@"light_tables/%@",_lightTable.identifier] parameters:@{@"light_table":parameters,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success saving a light table: %@", responseObject);
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(didUpdateLightTable:)]){
                [self.lightTableDelegate didUpdateLightTable:_lightTable];
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
    if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(showOwners)]){
        [self.lightTableDelegate showOwners];
    }
}

- (void)showMembers {
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
            if (newText.length && ((tableKeyTextField.text.length && [confirmTableKeyTextField.text isEqualToString:tableKeyTextField.text]) || _lightTable)){
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

- (void)doneEditing {
    if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(doneEditing)]){
        [self.lightTableDelegate doneEditing];
    }
}


@end
