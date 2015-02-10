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
#import "WFArtistsViewController.h"
#import "WFLocationsViewController.h"
#import "Location+helper.h"
#import "Constants.h"
#import "WFDateMetadataCell.h"
#import "WFMaterialsViewController.h"

@interface WFNewArtViewController () <UITableViewDataSource, UITableViewDelegate , UIScrollViewDelegate, UITextFieldDelegate, WFImagePickerControllerDelegate, WFSelectArtistsDelegate, WFSelectLocationsDelegate, WFDatePickerDelegate, WFSelectMaterialsDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    BOOL iOS8;
    BOOL selectingDate;
    CGFloat width;
    CGFloat height;
    UITextField *titleTextField;
    UITextField *dateTextField;
    UITextField *materialTextField;
    UISwitch *privacySwitch;
    UILabel *privateLabel;
    Art *_art;
    WFDatePicker *_datePicker;
    UIButton *_ceButton;
    UIButton *_bceButton;
}

@end

@implementation WFNewArtViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
    }
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _tableView.rowHeight = 50.f;
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
    [_photoCountLabel setTextColor:[UIColor colorWithWhite:1 alpha:.33]];
    [_photoCountLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSansLight] size:0]];
    
    [self registerKeyboardNotifications];
    //[self setupDatePicker];
}

//- (void)setupDatePicker {
//    _datePicker = [[WFDatePicker alloc] initWithFrame:CGRectMake(0, height, width, 216.f)];
//    _datePicker.datePickerDelegate = self;
//    [self.view addSubview:_datePicker];
//}

- (void)dateSelected:(NSDate *)date suffix:(NSString*)suffix circa:(BOOL)circa {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
    if (!_art.interval){
        Interval *interval = [Interval MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [_art setInterval:interval];
    }
    [_art.interval setYear:[NSNumber numberWithInteger:components.year]];
    [_art.interval setSuffix:suffix];
    _art.interval.circa = @(circa);
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];

    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [UIView animateWithDuration:.77 animations:^{
        if (_art.interval.year && ![_art.interval.year isEqualToNumber:@0]){
            NSString *suffix = _art.interval.suffix.length ? _art.interval.suffix : @"";
            [dateTextField setText:[NSString stringWithFormat:@"%@ %@",_art.interval.year, suffix]];
        } else {
            [dateTextField setText:@""];
        }
    }];
}

//- (void)showDatePicker {
//    selectingDate = YES;
//    [dateTextField setUserInteractionEnabled:YES];
//    [dateTextField becomeFirstResponder];
//}
//
//- (void)hideDatePicker {
//    selectingDate = NO;
//    [dateTextField setUserInteractionEnabled:NO];
//    [dateTextField resignFirstResponder];
//}

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
    [_addPhotoButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [_addPhotoButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
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
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    if (selectedImages.count) {
        NSString *photoCountText = selectedImages.count == 1 ? @"1 IMAGE" : [NSString stringWithFormat:@"%lu IMAGES",(unsigned long)selectedImages.count];
        [_photoCountLabel setText:photoCountText];
    } else {
        [_photoCountLabel setText:@""];
    }
    if (selectedImages.count && _submitButton.isHidden){
        [_submitButton setHidden:NO];
    }
    [self setUpPhotosScrollView];
}

- (void)setUpPhotosScrollView {
    [_scrollView setPagingEnabled:YES];
    _scrollView.showsHorizontalScrollIndicator = NO;
    [_scrollView setBackgroundColor:[UIColor clearColor]];
    [_art.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
        UIImageView *photoImage = [[UIImageView alloc] initWithImage:photo.image];
        [photoImage setFrame:CGRectMake(((_scrollView.frame.size.width-230)/2)+(_scrollView.frame.size.width*idx), (_scrollView.frame.size.height-230)/2, 230, 230)];
        [photoImage setContentMode:UIViewContentModeScaleAspectFill];
        photoImage.clipsToBounds = YES;
        [_scrollView addSubview:photoImage];
        
        UILabel *creditLabel = [[UILabel alloc] initWithFrame:CGRectMake(((_scrollView.frame.size.width-230)/2)+(_scrollView.frame.size.width*idx), _scrollView.frame.size.height-33, 60, 30)];
        [creditLabel setText:@"CREDIT:"];
        [creditLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSans] size:0]];
        [creditLabel setTextColor:[UIColor whiteColor]];
        [_scrollView addSubview:creditLabel];
        UITextField *creditTextField = [[UITextField alloc] initWithFrame:CGRectMake(creditLabel.frame.origin.x+creditLabel.frame.size.width, _scrollView.frame.size.height-33, 190, 30)];
        [creditTextField setBackgroundColor:[UIColor clearColor]];
        [creditTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
        [creditTextField setText:@"I took this photo"];
        [creditTextField setPlaceholder:@"Photo credit field..."];
        [creditTextField setTextColor:[UIColor whiteColor]];
        [creditTextField setTextAlignment:NSTextAlignmentLeft];
        [creditTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
        [_scrollView addSubview:creditTextField];
    }];
    [_scrollView addSubview:_addPhotoButton];
    [_scrollView setContentSize:CGSizeMake((_art.photos.count+1) * _scrollView.frame.size.width, _scrollView.frame.size.height)];
    [_addPhotoButton setFrame:CGRectMake(_scrollView.contentSize.width-_scrollView.frame.size.width, (_scrollView.frame.size.height-230)/2, 230, 230)];
    [_scrollView bringSubviewToFront:_addPhotoButton];
    
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
    NSMutableArray *artistIds = [NSMutableArray arrayWithCapacity:_art.artists.count];
    for (Artist *artist in _art.artists){
        [artistIds addObject:artist.identifier];
    }
    [parameters setObject:artistIds forKey:@"artist_ids"];
    
    NSMutableArray *locationIds = [NSMutableArray arrayWithCapacity:_art.locations.count];
    for (Location *location in _art.locations){
        [locationIds addObject:location.identifier];
    }
    [parameters setObject:locationIds forKey:@"location_ids"];
    
    if (materialTextField.text.length){
        [parameters setObject:materialTextField.text forKey:@"material"];
    }
    if (_art.interval){
        [parameters setObject:_art.interval.year forKey:@"year"];
        [parameters setObject:_art.interval.suffix forKey:@"suffix"];
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
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 54)];
    privateLabel = [[UILabel alloc] initWithFrame:CGRectMake(142, 25, self.tableView.frame.size.width-100, 27)];
    [privateLabel setBackgroundColor:[UIColor clearColor]];
    [privateLabel setTextColor:[UIColor whiteColor]];
    [privateLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [privateLabel setText:@"Would you like to keep this art private?"];
    [privateLabel sizeToFit];
    [tableFooterView addSubview:privateLabel];
    privacySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(privateLabel.frame.origin.x + privateLabel.frame.size.width+30, 20, 44, 44)];
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
    UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
    [selectedView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.05]];
    cell.selectedBackgroundView = selectedView;
    
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
            [cell.textField setUserInteractionEnabled:YES];
            break;
        case 1:
            [cell.label setText:@"ARTIST *"];
            [cell.textField setPlaceholder:@"Leave blank if artist unknown"];
            [cell.textField setText:_art.artistsToSentence];
            [cell.textField setReturnKeyType:UIReturnKeyNext];
            [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            [cell.textField setUserInteractionEnabled:NO];
            break;
        case 2:
        {
            WFDateMetadataCell *dateCell = [tableView dequeueReusableCellWithIdentifier:@"DateCell"];
            if (SYSTEM_VERSION < 8.f){
                [dateCell setBackgroundColor:[UIColor clearColor]];
            }
            dateTextField = dateCell.beginYearTextField;
            if ([_art.interval.suffix isEqualToString:@"CE"]){
                [dateCell.ceButton setSelected:YES];
                [dateCell.bceButton setSelected:NO];
            } else if ([_art.interval.suffix isEqualToString:@"BCE"]){
                [dateCell.ceButton setSelected:NO];
                [dateCell.bceButton setSelected:YES];
            }
            [dateCell configureForArt:_art];
            dateCell.selectedBackgroundView = selectedView;
            [dateCell.label setText:@"DATE *"];
            [dateCell.circaLabel setText:@"CIRCA"];
            [dateCell.beginYearTextField setPlaceholder:@"e.g. 1776"];
            [dateCell.beginYearTextField setKeyboardType:UIKeyboardTypeNumberPad];
            [dateCell.beginYearTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
            
            if (_art.interval.year && ![_art.interval.year isEqualToNumber:@0]){
                [dateCell.beginYearTextField setText:[NSString stringWithFormat:@"%@",_art.interval.year]];
                NSString *suffix = _art.interval.suffix.length ? _art.interval.suffix : @"";
                [dateCell.eraLabel setText:suffix];
            } else {
                [dateCell.beginYearTextField setText:@""];
                [dateCell.eraLabel setText:@""];
            }
            [dateCell.circaSwitch setOn:_art.interval.circa.boolValue animated:YES];
            [dateCell.circaSwitch addTarget:self action:@selector(circaSwitchSwitched:) forControlEvents:UIControlEventValueChanged];
            [dateCell.ceButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
            _ceButton = dateCell.ceButton;
            [_ceButton setShowsTouchWhenHighlighted:YES];
            [dateCell.bceButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
            _bceButton = dateCell.bceButton;
            [_bceButton setShowsTouchWhenHighlighted:YES];
            return dateCell;
        }
            break;
        case 3:
            [cell.label setText:@"LOCATION *"];
            [cell.textField setPlaceholder:@"e.g. Paris"];
            [cell.textField setText:_art.locationsToSentence];
            [cell.textField setUserInteractionEnabled:NO];
            break;
        case 4:
            [cell.label setText:@"MATERIALS"];
            [cell.textField setPlaceholder:@"e.g. clay, wrought iron, etc."];
            [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
            materialTextField = cell.textField;
            [cell.textField setText:_art.materialsToSentence];
            [cell.textField setUserInteractionEnabled:NO];
            break;
        default:
            break;
    }
    return cell;
}

- (void)eraTapped:(UIButton*)button {
    if (!_art.interval){
        Interval *interval = [Interval MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [_art setInterval:interval];
    }
    
    if (button == _ceButton){
        [_ceButton setSelected:YES];
        [_bceButton setSelected:NO];
        [_art.interval setSuffix:@"CE"];
    } else if (button == _bceButton){
        [_bceButton setSelected:YES];
        [_ceButton setSelected:NO];
        [_art.interval setSuffix:@"BCE"];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    NSLog(@"art interval suffix: %@",_art.interval.suffix);
    //[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)circaSwitchSwitched:(UISwitch*)circaSwitch {
    _art.interval.circa = @(circaSwitch.isOn);
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1){
        [self showArtists];
    } else if (indexPath.row == 3){
        [self showLocations];
    } else if (indexPath.row == 4){
        [self showMaterials];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showArtists {
    WFArtistsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Artists"];
    [vc setSelectedArtists:_art.artists.mutableCopy];
    vc.artistDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)artistsSelected:(NSOrderedSet *)selectedArtists {
    _art.artists = selectedArtists;
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showLocations {
    WFLocationsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Locations"];
    [vc setSelectedLocations:_art.locations.mutableCopy];
    vc.locationDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)locationsSelected:(NSOrderedSet *)selectedLocations {
    _art.locations = selectedLocations;
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showMaterials {
    WFMaterialsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Materials"];
    [vc setSelectedMaterials:_art.materials.mutableCopy];
    vc.materialDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)materialsSelected:(NSOrderedSet *)selectedMaterials {
    _art.materials = selectedMaterials;
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:4 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]){
        if (textField == titleTextField){
            [self showArtists];
        } else if (textField == dateTextField){
            [self showLocations];
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

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)willShowKeyboard:(NSNotification*)notification {
    //NSDictionary* keyboardInfo = [notification userInfo];
    //NSValue *keyboardValue = keyboardInfo[UIKeyboardFrameEndUserInfoKey];
    //CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
    //CGFloat keyboardHeight = convertedKeyboardFrame.size.height;
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
//                         if (selectingDate){
//                             _datePicker.transform = CGAffineTransformMakeTranslation(0, -(_datePicker.frame.size.height+keyboardHeight));
//                             _slideContainerView.transform = CGAffineTransformMakeTranslation(0, -_datePicker.frame.size.height/2);
//                             _tableView.transform = CGAffineTransformMakeTranslation(0, -_datePicker.frame.size.height/2);
//                             [privacySwitch setAlpha:0.0];
//                             [privateLabel setAlpha:0.0];
//                         }
                     }
                     completion:^(BOOL finished) {

                     }];
}

- (void)willHideKeyboard:(NSNotification *)notification {
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
//                         _datePicker.transform = CGAffineTransformIdentity;
//                         _slideContainerView.transform = CGAffineTransformIdentity;
//                         _tableView.transform = CGAffineTransformIdentity;
//                         [privacySwitch setAlpha:1.0];
//                         [privateLabel setAlpha:1.0];
                     }
                     completion:NULL];
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == dateTextField && dateTextField.text.length){
        if (!_art.interval){
            Interval *interval = [Interval MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [_art setInterval:interval];
        }
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *yearNumber = [f numberFromString:dateTextField.text];
        if (yearNumber){
            _art.interval.year = yearNumber;
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            NSLog(@"Not a number");
        }
    }
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
