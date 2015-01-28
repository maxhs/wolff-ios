//
//  WFNewArtViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/23/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFNewArtViewController.h"
#import "WFAppDelegate.h"
#import "WFNewArtCell.h"
#import "Art+helper.h"
#import "WFAssetGroupPickerController.h"
#import "WFImagePickerController.h"
#import "WFAlert.h"

@interface WFNewArtViewController () <UITableViewDataSource, UITableViewDelegate , UIScrollViewDelegate, UITextFieldDelegate, WFImagePickerControllerDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UITextField *titleTextField;
    UITextField *artistTextField;
    UITextField *dateTextField;
    UITextField *locationTextField;
    UITextField *materialTextField;
    UISwitch *privacySwitch;
    Art *_art;
}

@end

@implementation WFNewArtViewController

- (void)viewDidLoad {
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self setupTableFooter];
    [self setupSlideContainer];
    _art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [_dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [_submitButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    [_submitButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_submitButton addTarget:self action:@selector(post) forControlEvents:UIControlEventTouchUpInside];
    _submitButton.layer.cornerRadius = 14.f;
    _submitButton.clipsToBounds = YES;
    [_photoCountLabel setTextColor:[UIColor whiteColor]];
    [_photoCountLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [titleTextField becomeFirstResponder];
}

- (void)setupSlideContainer {
    [_slideContainerView setBackgroundColor:kSlideBackgroundColor];
    _slideContainerView.layer.cornerRadius = 14.f;
    _slideContainerView.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:.23].CGColor;
    _slideContainerView.clipsToBounds = NO;
    
    [_addPhotoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [_addPhotoButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [_addPhotoButton addTarget:self action:@selector(showPhotoOptions) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showPhotoOptions {
    //UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"SELECT A PHOTO" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Choose Photo",@"Take Photo", nil];
    [self choosePhoto];
}

- (void)choosePhoto {
    WFAssetGroupPickerController *imagePicker = [[self storyboard] instantiateViewControllerWithIdentifier:@"AssetGroupPicker"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imagePicker];
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)didFinishPickingPhotos:(NSMutableArray *)selectedImages {
    for (UIImage *image in selectedImages){
        Photo *photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [photo setImage:image];
        [_art addPhoto:photo];
    }
    [_addPhotoButton setImage:selectedImages.firstObject forState:UIControlStateNormal];
    [_addPhotoButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    _addPhotoButton.imageView.clipsToBounds = YES;
    if (selectedImages.count) {
        NSString *photoCountText = selectedImages.count == 1 ? @"1 image selected" : [NSString stringWithFormat:@"%lu images selected",(unsigned long)selectedImages.count];
        [_photoCountLabel setText:photoCountText];
    } else {
        [_photoCountLabel setText:@""];
    }
    if (selectedImages.count && _submitButton.isHidden){
        [_submitButton setHidden:NO];
    }
}

- (void)post {
    [self.view endEditing:YES];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    if (titleTextField.text.length){
        [parameters setObject:titleTextField.text forKey:@"title"];
    } else {
        [WFAlert show:@"Please make sure you've added a title before submitting." withTime:3.3f];
        return;
    }
    
    if (materialTextField.text.length){
        [parameters setObject:materialTextField.text forKey:@"material"];
    }
    if (dateTextField.text.length){
        [parameters setObject:dateTextField.text forKey:@"year"];
    }
    if (locationTextField.text.length){
        [parameters setObject:locationTextField.text forKey:@"location"];
    }
    if ([_art.privateArt isEqualToNumber:@YES]){
        [parameters setObject:@1 forKey:@"private"];
    } else {
        [parameters setObject:@0 forKey:@"private"];
    }
    
    [manager POST:@"arts" parameters:@{@"art":parameters} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        for (Photo *photo in _art.photos){
            NSData *imageData = UIImageJPEGRepresentation(photo.image, 1);
            [formData appendPartWithFileData:imageData name:@"photos[][image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
        }
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating art: %@",responseObject);
        [_art populateFromDictionary:[responseObject objectForKey:@"art"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.artDelegate && [self.artDelegate respondsToSelector:@selector(newArtAdded:)]){
                [self.artDelegate newArtAdded:_art];
            }
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error creating art: %@",error.description);
        if (self.artDelegate && [self.artDelegate respondsToSelector:@selector(failedToAddArt:)]){
            [self.artDelegate failedToAddArt:_art];
        }
    }];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [WFAlert show:@"We're adding your art to the catalog!\n\nThis may take a few minutes..." withTime:3.3f];
    }];
}

- (void)setupTableFooter {
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 84)];
    UILabel *privateLabel = [[UILabel alloc] initWithFrame:CGRectMake(142, 44, self.tableView.frame.size.width-100, 27)];
    [privateLabel setBackgroundColor:[UIColor clearColor]];
    [privateLabel setTextColor:[UIColor whiteColor]];
    [privateLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [privateLabel setText:@"Would you like to keep this art private?"];
    [privateLabel sizeToFit];
    [tableFooterView addSubview:privateLabel];
    privacySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(privateLabel.frame.origin.x + privateLabel.frame.size.width+30, 38, 44, 44)];
    [privacySwitch addTarget:self action:@selector(switchSwitched:) forControlEvents:UIControlEventValueChanged];
    [tableFooterView addSubview:privacySwitch];
    self.tableView.tableFooterView = tableFooterView;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFNewArtCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewArtCell"];
    if (SYSTEM_VERSION < 8.f){
        [cell setBackgroundColor:[UIColor clearColor]];
    }
    cell.textField.delegate = self;
    [cell.textField setHidden:NO];
    [cell.textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    switch (indexPath.row) {
        case 0:
            [cell.label setText:@"TITLE *"];
            [cell.textField setPlaceholder:@"Art title"];
            [cell.textField setReturnKeyType:UIReturnKeyNext];
            titleTextField = cell.textField;
            [titleTextField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
            break;
        case 1:
            [cell.label setText:@"ARTIST"];
            [cell.textField setPlaceholder:@"Artist"];
            artistTextField = cell.textField;
            [cell.textField setReturnKeyType:UIReturnKeyNext];
            [artistTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            break;
        case 2:
            [cell.label setText:@"DATE"];
            [cell.textField setPlaceholder:@"e.g. 1776"];
            [cell.textField setKeyboardType:UIKeyboardTypeNumberPad];
            [cell.textField setReturnKeyType:UIReturnKeyNext];
            dateTextField = cell.textField;
            break;
        case 3:
            [cell.label setText:@"LOCATION"];
            [cell.textField setPlaceholder:@"e.g. Paris"];
            locationTextField = cell.textField;
            [cell.textField setReturnKeyType:UIReturnKeyNext];
            [locationTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            break;
        case 4:
            [cell.label setText:@"MATERIAL"];
            [cell.textField setPlaceholder:@"e.g. clay, wrought iron, etc."];
            [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
            materialTextField = cell.textField;
            break;
        default:
            break;
    }
    return cell;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]){
        if (textField == titleTextField){
            [artistTextField becomeFirstResponder];
        } else if (textField == artistTextField){
            [dateTextField becomeFirstResponder];
        } else if (textField == dateTextField){
            [locationTextField becomeFirstResponder];
        } else if (textField == locationTextField){
            [materialTextField becomeFirstResponder];
        }
        return NO;
    } else {
        return YES;
    }
}

- (void)switchSwitched:(UISwitch*)thisSwitch {
    if (thisSwitch.isOn){
        [_art setPrivateArt:@YES];
    } else {
        [_art setPrivateArt:@NO];
    }
}

- (void)showPhotoLibrary {
    
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
