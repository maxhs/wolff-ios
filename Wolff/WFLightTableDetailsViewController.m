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

#define kLightTableDescriptionPlaceholder @"Describe your light table..."

@interface WFLightTableDetailsViewController () < UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UITextField *titleTextField;
    UITextField *tableKeyTextField;
    UITextField *confirmTableKeyTextField;
    UITextView *descriptionTextView;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *createButton;
    UIImageView *navBarShadowView;
}

@end

@implementation WFLightTableDetailsViewController
@synthesize arts = _arts;
@synthesize photos = _photos;
@synthesize table = _table;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
    UIToolbar *backgroundView = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [backgroundView setTranslucent:YES];
    [backgroundView setBarStyle:UIBarStyleDefault];
    [self.tableView setBackgroundView:backgroundView];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.03]];
    
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    dismissButton.tintColor = [UIColor blackColor];
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    self.title = @"New Light Table";
    
    _table = [Table MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    if (_photos.count){
        NSLog(@"Should be pre-seeding table with %d image objects",_photos.count);
    }
}

- (void)setUpFooterView {
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 60)];
    [footerView setBackgroundColor:[UIColor clearColor]];
    
    CGFloat originX = 140;
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(originX, 0, self.tableView.frame.size.width-originX*2, footerView.frame.size.height)];
    [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [headerLabel setTextColor:[UIColor colorWithWhite:.5 alpha:.7]];
    [headerLabel setText:@"The table key is like a password for your light table. Invite others to your light table by sharing this key."];
    headerLabel.numberOfLines = 0;
    [footerView addSubview:headerLabel];
    self.tableView.tableFooterView = footerView;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFLightTableDetailsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LightTableDetailsCell" forIndexPath:indexPath];
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
            [cell.textField setPlaceholder:@"Your table key"];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1){
        return 88;
    } else {
        return 44;
    }
}

- (void)createLightTable {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (titleTextField.text.length){
        [parameters setObject:titleTextField.text forKey:@"name"];
    }
    if (descriptionTextView.text.length){
        [parameters setObject:descriptionTextView.text forKey:@"description"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"owner_id"];
    }
    if (tableKeyTextField.text.length && [tableKeyTextField.text isEqualToString:confirmTableKeyTextField.text]){
        [parameters setObject:tableKeyTextField.text forKey:@"code"];
    }
    [ProgressHUD show:@"Creating light table..."];
    [manager POST:@"light_tables" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [_table populateFromDictionary:[responseObject objectForKey:@"table"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD dismiss];
        }];
        NSLog(@"Success creating a light table: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        NSLog(@"Error creating a light table: %@",error.description);
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

- (void)doneEditing {
    [self.view endEditing:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        if (textField == tableKeyTextField){
            [confirmTableKeyTextField becomeFirstResponder];
        } else if (textField == confirmTableKeyTextField) {
            //[self connect];
        }
    }
    return YES;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
