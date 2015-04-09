//
//  WFFlagViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/22/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFFlagViewController.h"
#import "WFAppDelegate.h"
#import "Art+helper.h"
#import "Photo+helper.h"
#import "WFFlagCell.h"
#import "WFAlert.h"
#import "WFArtMetadataViewController.h"

@interface WFFlagViewController () <UITextFieldDelegate> {
    AFHTTPRequestOperationManager *manager;
    WFAppDelegate *delegate;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *submitButton;
    UISwitch *copyrightSwitch;
    UISwitch *accuracySwitch;
    UISwitch *damagesSwitch;
    UITextField *titleTextField;
    UITextField *artistTextField;
    UITextField *locationTextField;
    UITextField *dateTextField;
    UITextField *materialTextField;
    UITextField *iconographyTextField;
    UITextField *creditTextField;
    UITextField *notesTextField;
    UITextField *copyrightOwnerTextField;
    UITextField *myNameTextField;
    UITextField *emailTextField;
    UITextField *phoneTextField;
    UITextField *userAddressTextField;
    UITextField *cityStateCountryTextField;
    CGFloat keyboardHeight;
    CGFloat topInset;
}

@end

@implementation WFFlagViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    submitButton = [[UIBarButtonItem alloc] initWithTitle:@"Submit" style:UIBarButtonItemStylePlain target:self action:@selector(createFlag)];
    submitButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = submitButton;
    copyrightSwitch = [[UISwitch alloc] init];
    accuracySwitch = [[UISwitch alloc] init];
    damagesSwitch = [[UISwitch alloc] init];
    
    if (self.art){
        [_headerLabel setText:[NSString stringWithFormat:@"Flagging \"%@\"",self.art.title]];
    } else if (self.photo) {
        [_headerLabel setText:[NSString stringWithFormat:@"Flagging \"%@\"",self.photo.art.title]];
    } else {
        [_headerLabel setText:[NSString stringWithFormat:@"Adding a flag"]];
    }
    self.currentUser = [self.currentUser MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    
    [_headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [_headerLabel setTextColor:[UIColor redColor]];
    self.tableView.tableHeaderView = _headerLabel;
    self.tableView.rowHeight = 60.f;
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:0 alpha:.1]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self registerForKeyboardNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    topInset = self.tableView.contentInset.top; // have to set it here, not viewDidLoad
    if (_copyright){
        [copyrightOwnerTextField becomeFirstResponder];
    } else {
        [titleTextField becomeFirstResponder];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.copyright){
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_copyright){
        if (section == 0){
            return 6;
        } else {
            return 3;
        }
    } else {
        return 8;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFFlagCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FlagCell" forIndexPath:indexPath];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    cell.textField.delegate = self;
    
    CGRect mainLabelRect = cell.label.frame;
    if (self.copyright){
        if (indexPath.section == 0){
            mainLabelRect.size.height = 60.f;
            [cell.label setFrame:mainLabelRect];
            [cell.flagSwitch setHidden:YES];
            [cell.textField setHidden:NO];
            [cell.textField setKeyboardType:UIKeyboardTypeDefault];
            [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            [cell.textField setReturnKeyType:UIReturnKeyNext];
            switch (indexPath.row) {
                case 0:
                    [cell.textFieldLabel setText:@"COPYRIGHT OWNER"];
                    [cell.textField setPlaceholder:@"Copyright owner name"];
                    copyrightOwnerTextField = cell.textField;
                    break;
                case 1:
                    [cell.textFieldLabel setText:@"MY NAME"];
                    [cell.textField setPlaceholder:@"My full legal name"];
                    [cell.textField setText:self.currentUser.fullName];
                    myNameTextField = cell.textField;
                    break;
                case 2:
                    [cell.textFieldLabel setText:@"EMAIL"];
                    [cell.textField setPlaceholder:@"My email address"];
                    [cell.textField setText:self.currentUser.email];
                    [cell.textField setKeyboardType:UIKeyboardTypeEmailAddress];
                    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                    emailTextField = cell.textField;
                    break;
                case 3:
                    [cell.textFieldLabel setText:@"PHONE"];
                    [cell.textField setPlaceholder:@"My phone number"];
                    [cell.textField setText:self.currentUser.phone];
                    phoneTextField = cell.textField;
                    break;
                case 4:
                    [cell.textFieldLabel setText:@"ADDRESS"];
                    [cell.textField setPlaceholder:@"My address"];
                    userAddressTextField = cell.textField;
                    break;
                case 5:
                    [cell.textFieldLabel setText:@"CITY/STATE/COUNTRY"];
                    [cell.textField setPlaceholder:@"City, State, Country"];
                    cityStateCountryTextField = cell.textField;
                    break;
                case 6:
                    [cell.textFieldLabel setText:@"NOTES"];
                    notesTextField = cell.textField;
                    notesTextField.placeholder = @"Why are you creating this flag?";
                    [cell.textField setReturnKeyType:UIReturnKeyDone];
                    break;
                default:
                    break;
            }
        } else {
            [cell.textFieldLabel setText:@""];
            [cell.flagSwitch setHidden:NO];
            [cell.textField setHidden:YES];
            mainLabelRect.size.height = 100.f;
            [cell.label setFrame:mainLabelRect];
            switch (indexPath.row) {
                case 0:
                    copyrightSwitch = cell.flagSwitch;
                    [cell.label setText:@"I hereby state that I have a good faith belief that the sharing of copyrighted material at the location above is not authorized by the copyright owner, its agent, or the law (e.g. as fair use)."];
                    break;
                case 1:
                    accuracySwitch = cell.flagSwitch;
                    [cell.label setText:@"I hereby state that the information in this Notice is accurate and, under penalty of perjury, that I am the owner, or authorized to act on behalf of the owner, of the copyright or of an exclusive right under the copyright that is allegedly infringed."];
                    break;
                case 2:
                    damagesSwitch = cell.flagSwitch;
                    [cell.label setText:@"I acknowledge that under Section 512(f) any person who knowingly materially misrepresents that material or activity is infringing may be subject to liability for damages."];
                    break;
                    
                default:
                    break;
            }
        }
    } else {
        [cell.flagSwitch setHidden:YES];
        [cell.textField setHidden:NO];
        switch (indexPath.row) {
            case 0:
                [cell.textFieldLabel setText:@"TITLE"];
                titleTextField = cell.textField;
                titleTextField.placeholder = @"Is the title incorrect?";
                break;
            case 1:
                [cell.textFieldLabel setText:@"ARTIST(S)"];
                artistTextField = cell.textField;
                artistTextField.placeholder = @"Why is the artist incorrect?";
                break;
            case 2:
                [cell.textFieldLabel setText:@"DATE"];
                dateTextField = cell.textField;
                dateTextField.placeholder = @"Is the date wrong?";
                break;
            case 3:
                [cell.textFieldLabel setText:@"LOCATION"];
                locationTextField = cell.textField;
                locationTextField.placeholder = @"Bad location?";
                break;
            case 4:
                [cell.textFieldLabel setText:@"MATERIAL(S)"];
                materialTextField = cell.textField;
                materialTextField.placeholder = @"Wrong material(s)?";
                break;
            case 5:
                [cell.textFieldLabel setText:@"ICONOGRAPHY"];
                iconographyTextField = cell.textField;
                iconographyTextField.placeholder = @"Is the iconography wrong?";
                break;
            case 6:
                [cell.textFieldLabel setText:@"CREDIT/RIGHTS"];
                creditTextField = cell.textField;
                creditTextField.placeholder = @"Who should have the credit for this piece?";
                break;
            case 7:
                [cell.textFieldLabel setText:@"NOTES"];
                notesTextField = cell.textField;
                notesTextField.placeholder = @"Why are you creating this flag?";
                break;                
            default:
                break;
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        return 60.f;
    } else {
        return 100.f;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = doneButton;
    if (textField == copyrightOwnerTextField){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    } else if (textField == userAddressTextField){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:4 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    } else if (textField == iconographyTextField){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:5 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    } else if (textField == creditTextField){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:6 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)createFlag {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSMutableDictionary *flagDict = [NSMutableDictionary dictionary];
    if (self.art){
        [flagDict setObject:self.art.identifier forKey:@"art_id"];
    }
    if (self.photo){
        [flagDict setObject:self.photo.identifier forKey:@"photo_id"];
    }
    
    if (self.copyright) {
        if (copyrightOwnerTextField.text.length){
            [parameters setObject:copyrightOwnerTextField.text forKey:@"copyright_owner"];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Copyright Flag" message:@"A copyright flag requires that you name the copyright owner. Please ensure this field is filled out before continuing." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    } else {
        [parameters setObject:@YES forKey:@"metadata"];
        if (titleTextField.text.length){
            [parameters setObject:titleTextField.text forKey:@"title"];
        }
        if (artistTextField.text.length){
            [parameters setObject:artistTextField.text forKey:@"artist"];
        }
        if (dateTextField.text.length){
            [parameters setObject:dateTextField.text forKey:@"date"];
        }
        if (locationTextField.text.length){
            [parameters setObject:locationTextField.text forKey:@"location"];
        }
        if (materialTextField.text.length){
            [parameters setObject:materialTextField.text forKey:@"material"];
        }
        if (iconographyTextField.text.length){
            [parameters setObject:iconographyTextField.text forKey:@"iconography"];
        }
        if (materialTextField.text.length){
            [parameters setObject:materialTextField.text forKey:@"material"];
        }
        if (creditTextField.text.length){
            [parameters setObject:creditTextField.text forKey:@"credit"];
        }
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [flagDict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    [parameters setObject:flagDict forKey:@"flag"];
    
    [manager POST:@"flags" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a flag: %@",responseObject);
        WFArtMetadataViewController *vc = (WFArtMetadataViewController*)self.navigationController.viewControllers.firstObject;
        if (vc.metadataDelegate && [vc.metadataDelegate respondsToSelector:@selector(artFlagged:)]){
            [vc.metadataDelegate artFlagged:self.photo.art];
        }
        [self.navigationController popToRootViewControllerAnimated:YES];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (double).5f * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [WFAlert show:@"Flagged" withTime:2.3f];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [WFAlert show:@"Sorry, but something went wrong while trying to flag this art. Please try again soon." withTime:3.3f];
        NSLog(@"Failed to create flag: %@",error.description);
    }];
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.copyright){
        if (!copyrightSwitch.isOn){
            submitButton.enabled = NO;
        } else if (copyrightOwnerTextField.text.length) {
            submitButton.enabled = YES;
        } else {
            submitButton.enabled = NO;
        }
        if ([string isEqualToString:@"\n"]){
            if (textField == copyrightOwnerTextField){
                [myNameTextField becomeFirstResponder];
            } else if (textField == myNameTextField) {
                [emailTextField becomeFirstResponder];
            } else if (textField == emailTextField){
                [phoneTextField becomeFirstResponder];
            } else if (textField == phoneTextField){
                [userAddressTextField becomeFirstResponder];
            } else if (textField == userAddressTextField){
                [cityStateCountryTextField becomeFirstResponder];
            } else if (textField == cityStateCountryTextField){
                [notesTextField becomeFirstResponder];
            } else if (textField == notesTextField){
                [self createFlag];
            }
        }
    } else {
        if (titleTextField.text.length || materialTextField.text.length || artistTextField.text.length || iconographyTextField.text.length || dateTextField.text.length || locationTextField.text.length){
            submitButton.enabled = YES;
        } else {
            submitButton.enabled = NO;
        }
        if ([string isEqualToString:@"\n"]){
            if (textField == titleTextField){
                [artistTextField becomeFirstResponder];
            } else if (textField == artistTextField) {
                [dateTextField becomeFirstResponder];
            } else if (textField == dateTextField){
                [locationTextField becomeFirstResponder];
            } else if (textField == locationTextField){
                [materialTextField becomeFirstResponder];
            } else if (textField == materialTextField){
                [iconographyTextField becomeFirstResponder];
            } else if (textField == iconographyTextField){
                [creditTextField becomeFirstResponder];
            } else if (textField == creditTextField){
                [notesTextField becomeFirstResponder];
            } else if (textField == notesTextField){
                [self createFlag];
            }
        }
    }
    return YES;
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
    self.keyboardVisible = YES;
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameEndUserInfoKey];
    CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
    keyboardHeight = convertedKeyboardFrame.size.height;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight+34, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight+34, 0);
                     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)note {
    self.keyboardVisible = NO;
    self.navigationItem.rightBarButtonItem = submitButton;
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, 0, 0);
                     }
                     completion:nil];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    self.navigationItem.rightBarButtonItem = submitButton;
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
