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

@interface WFNewArtViewController () <UITableViewDataSource, UITableViewDelegate , UIScrollViewDelegate, WFImagePickerControllerDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UITextField *titleTextField;
    UITextField *artistTextField;
    UITextField *dateTextField;
    UITextField *locationTextField;
    UITextField *materialTextField;
    UISwitch *privacySwitch;
    Art *_art;
    UIButton *createButton;
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
//    _slideContainerView.layer.shadowColor = [UIColor colorWithWhite:.5 alpha:1].CGColor;
//    _slideContainerView.layer.shadowOpacity = .4f;
//    _slideContainerView.layer.shadowOffset = CGSizeMake(1.3f, 1.7f);
//    _slideContainerView.layer.shadowRadius = 1.3f;
//    
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
    if (selectedImages.count && createButton.hidden){
        [createButton setHidden:NO];
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
    if ([_art.privateArt isEqualToNumber:@YES]){
        [parameters setObject:@1 forKey:@"private"];
    } else {
        [parameters setObject:@0 forKey:@"private"];
    }
    
    NSData *imageData = UIImageJPEGRepresentation(_art.photo.image, 1);
    [manager POST:@"arts" parameters:@{@"art":parameters, @"photo[user_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating art: %@",responseObject);
        [_art populateFromDictionary:[responseObject objectForKey:@"art"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                
            }];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error creating art: %@",error.description);
    }];
}

- (void)setupTableFooter {
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 84)];
    createButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [tableFooterView addSubview:createButton];
    [createButton setFrame:CGRectMake(10, 20, tableFooterView.frame.size.width-20, 44)];
    [createButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
    [createButton setTitle:@"ADD" forState:UIControlStateNormal];
    [createButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [createButton addTarget:self action:@selector(post) forControlEvents:UIControlEventTouchUpInside];
    createButton.layer.cornerRadius = 14.f;
    createButton.clipsToBounds = YES;
    [createButton setHidden:YES];
    
    self.tableView.tableFooterView = tableFooterView;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFNewArtCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewArtCell"];
    if (SYSTEM_VERSION < 8.f){
        //[cell awakeFromNib];
        [cell setBackgroundColor:[UIColor clearColor]];
    }
    [cell.textField setHidden:NO];
    [cell.textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    switch (indexPath.row) {
        case 0:
            [cell.label setText:@"TITLE"];
            [cell.textField setPlaceholder:@"Art title"];
            titleTextField = cell.textField;
            [titleTextField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
            break;
        case 1:
            [cell.label setText:@"ARTIST"];
            [cell.textField setPlaceholder:@"Artist"];
            artistTextField = cell.textField;
            break;
        case 2:
            [cell.label setText:@"DATE"];
            [cell.textField setPlaceholder:@"e.g. 1776"];
            dateTextField = cell.textField;
            break;
        case 3:
            [cell.label setText:@"LOCATION"];
            [cell.textField setPlaceholder:@"e.g. Paris"];
            locationTextField = cell.textField;
            [locationTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            break;
        case 4:
            [cell.label setText:@"MATERIAL"];
            [cell.textField setPlaceholder:@"e.g. clay, wrought iron, etc."];
            materialTextField = cell.textField;
            break;
        case 5:
            [cell.label setText:@""];
            [cell.textLabel setText:@""];
            [cell.textField setHidden:YES];
            break;
        case 6:
        {
            [cell.label setText:@""];
            [cell.textField setHidden:YES];
            [cell.textLabel setText:@"Would you like to keep this art private?"];
            privacySwitch  = [[UISwitch alloc] init];
            [privacySwitch addTarget:self action:@selector(switchSwitched:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = privacySwitch;
        }
            break;
            
        default:
            break;
    }
    return cell;
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
