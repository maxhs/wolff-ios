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
#import "WFIconsViewController.h"

@interface WFNewArtViewController () <UITableViewDataSource, UITableViewDelegate , UIScrollViewDelegate, UITextFieldDelegate, WFImagePickerControllerDelegate, WFSelectArtistsDelegate, WFSelectLocationsDelegate, WFDatePickerDelegate, WFSelectMaterialsDelegate, WFSelectIconsDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    BOOL iOS8;
    BOOL selectingDate;
    CGFloat width;
    CGFloat height;
    UITextField *titleTextField;
    UITextField *dateTextField;
    UITextField *beginDateTextField;
    UITextField *endDateTextField;
    UITextField *materialTextField;
    UITextField *notesTextField;
    Art *_art;
    WFDatePicker *_datePicker;
    UIButton *_ceButton;
    UIButton *_bceButton;
    NSInteger currentPhotoIdx;
    NSMutableArray *_selectedImages;
    CGFloat imageWidth;
    CGFloat imageHeight;
    Photo *_currentPhoto;
    User *_currentUser;
}

@end

@implementation WFNewArtViewController

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
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    imageWidth = 262.f;
    imageHeight = 170.f;
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
    
    [_privateLabel setBackgroundColor:[UIColor clearColor]];
    [_privateLabel setTextColor:[UIColor whiteColor]];
    [_privateLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_privateLabel setText:@"MAKE ART PRIVATE"];
    [_privacySwitch addTarget:self action:@selector(switchSwitched:) forControlEvents:UIControlEventValueChanged];
    [_privacySwitch setOn:NO];
    
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
}

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
    _selectedImages = selectedImages;
    for (UIImage *image in selectedImages){
        Photo *photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [photo setImage:image];
        [_art addPhoto:photo];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    if (selectedImages.count && _submitButton.isHidden){
        [_submitButton setHidden:NO];
    }
    if (selectedImages.count == 1){
        [_photoCountLabel setText:@"1 image"];
    } else if (selectedImages.count == 0) {
        [_photoCountLabel setText:@""];
    } else {
        [self setPhotoCount];
    }
    
    [self drawPhotosScrollView];
    _currentPhoto = _art.photos.firstObject;
}

- (void)setPhotoCount {
    if (currentPhotoIdx >= _selectedImages.count){
        [_photoCountLabel setText:@"+ Photo"];
    } else {
        [_photoCountLabel setText:[NSString stringWithFormat:@"%lu of %lu",(unsigned long)currentPhotoIdx + 1,(unsigned long)_selectedImages.count]];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == _scrollView){
        CGFloat contentSizeWidth = scrollView.frame.size.width;
        CGFloat offsetX = scrollView.contentOffset.x;
        float fractionalPage = offsetX / contentSizeWidth;
        NSInteger page = lround(fractionalPage);
        if (currentPhotoIdx != page) {
            currentPhotoIdx = page;
            if (currentPhotoIdx < _selectedImages.count){
                _currentPhoto = _selectedImages[currentPhotoIdx];
            }
            [self setPhotoCount];
        }
    }
}

- (void)drawPhotosScrollView {
    [_scrollView setPagingEnabled:YES];
    _scrollView.delegate = self;
    _scrollView.showsHorizontalScrollIndicator = NO;
    [_scrollView setBackgroundColor:[UIColor clearColor]];
    [_scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [_art.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
        WFNewPhotoContainerView *containerView = [[WFNewPhotoContainerView alloc] initWithFrame:CGRectMake(0 + (idx*_scrollView.frame.size.width), 0, _scrollView.frame.size.width, _scrollView.frame.size.height)];
        [containerView setTag:idx];
        [_scrollView addSubview:containerView];
        
        containerView.photoImageView = [[UIImageView alloc] initWithImage:photo.image];
        [containerView.photoImageView setFrame:CGRectMake(((_scrollView.frame.size.width-imageWidth)/2)+(_scrollView.frame.size.width*idx), 20, imageWidth, imageHeight)];
        [containerView.photoImageView setContentMode:UIViewContentModeScaleAspectFill];
        containerView.photoImageView.clipsToBounds = YES;
        [containerView addSubview:containerView.photoImageView];
        
        containerView.creditLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, containerView.photoImageView.frame.size.height+containerView.photoImageView.frame.origin.y + 56.f, 100, 43)];
        [containerView.creditLabel setText:@"CREDIT / RIGHTS:"];
        [containerView.creditLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSansLight] size:0]];
        [containerView.creditLabel setTextColor:[UIColor lightGrayColor]];
        [containerView addSubview:containerView.creditLabel];
        
        containerView.creditTextField = [[UITextField alloc] initWithFrame:CGRectMake(containerView.creditLabel.frame.origin.x+containerView.creditLabel.frame.size.width + 3, containerView.photoImageView.frame.size.height+containerView.photoImageView.frame.origin.y + 56.f, 157, 43)];
        containerView.creditTextField.tag = idx;
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 43)];
        containerView.creditTextField.leftView = paddingView;
        containerView.creditTextField.leftViewMode = UITextFieldViewModeAlways;
        
        [containerView.creditTextField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
        [containerView.creditTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
        [containerView.creditTextField setText:_currentUser.fullName];
        [containerView.creditTextField setPlaceholder:@"Photo credit field..."];
        [containerView.creditTextField setTextColor:[UIColor whiteColor]];
        [containerView.creditTextField setTextAlignment:NSTextAlignmentCenter];
        [containerView.creditTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
        [containerView addSubview:containerView.creditTextField];
        
        containerView.iconographyLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, containerView.photoImageView.frame.size.height+containerView.photoImageView.frame.origin.y + 10.f, 100, 43)];
        [containerView.iconographyLabel setText:@"ICONOGRAPHY:"];
        [containerView.iconographyLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSansLight] size:0]];
        [containerView.iconographyLabel setTextColor:[UIColor lightGrayColor]];
        [containerView addSubview:containerView.iconographyLabel];
        
        containerView.iconographyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [containerView.iconographyButton addTarget:self action:@selector(showIcons) forControlEvents:UIControlEventTouchUpInside];
        [containerView.iconographyButton setFrame:CGRectMake(containerView.creditLabel.frame.origin.x+containerView.creditLabel.frame.size.width + 3, containerView.photoImageView.frame.size.height+containerView.photoImageView.frame.origin.y + 10.f, 157, 43)];
        [containerView.iconographyButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
        [containerView.iconographyButton setTitle:photo.iconsToSentence forState:UIControlStateNormal];
        [containerView.iconographyButton.titleLabel setNumberOfLines:0];
        [containerView.iconographyButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
        [containerView addSubview:containerView.iconographyButton];
    }];
    
    [_scrollView addSubview:_addPhotoButton];
    [_scrollView setContentSize:CGSizeMake((_art.photos.count+1) * _scrollView.frame.size.width, _scrollView.frame.size.height)];
    
    [_addPhotoButton setFrame:CGRectMake(_scrollView.contentSize.width-_scrollView.frame.size.width, 0, _slideContainerView.frame.size.width, _slideContainerView.frame.size.height)];
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
    
    NSMutableArray *materialIds = [NSMutableArray arrayWithCapacity:_art.materials.count];
    for (Material *material in _art.materials){
        [materialIds addObject:material.identifier];
    }
    [parameters setObject:materialIds forKey:@"material_ids"];
    
    if (notesTextField.text.length){
        [parameters setObject:notesTextField.text forKey:@"notes"];
    }
    NSLog(@"art.interval? %@",_art.interval);
    if (_art.interval){
        [parameters setObject:_art.interval.year forKey:@"interval[year]"];
        if (![_art.interval.beginRange isEqualToNumber:@0]){
            [parameters setObject:_art.interval.beginRange forKey:@"interval[begin_range]"];
        }
        if (![_art.interval.endRange isEqualToNumber:@0]){
            [parameters setObject:_art.interval.endRange forKey:@"interval[end_range]"];
        }
        if (![_art.interval.circa isEqualToNumber:@0]){
            [parameters setObject:_art.interval.circa forKey:@"interval[circa]"];
        }
        if (![_art.interval.year isEqualToNumber:@0]){
            [parameters setObject:_art.interval.year forKey:@"interval[year]"];
        }
        if (_art.interval.suffix && _art.interval.suffix.length){
            [parameters setObject:_art.interval.suffix forKey:@"interval[suffix]"];
        }
    }

    if ([_art.privateArt isEqualToNumber:@YES]){
        [parameters setObject:@1 forKey:@"private"];
    } else {
        [parameters setObject:@0 forKey:@"private"];
    }
    
    for (Photo *photo in _art.photos){
        [parameters setObject:photo.credit forKey:@"photos[][credit]"];
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
        [WFAlert show:@"We're adding your art to the catalog!\n\nThis may take a few minutes. You can also add additional metadata on wolffapp.com." withTime:3.3f];
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
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
            [cell.label setText:@"TITLE"];
            [cell.textField setPlaceholder:@"Art title"];
            [cell.textField setReturnKeyType:UIReturnKeyNext];
            titleTextField = cell.textField;
            [titleTextField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
            [cell.textField setUserInteractionEnabled:YES];
            break;
        case 1:
            [cell.label setText:@"ARTIST"];
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
            
            dateTextField = dateCell.singleYearTextField;
            dateTextField.delegate = self;
            beginDateTextField = dateCell.beginYearTextField;
            beginDateTextField.delegate = self;
            endDateTextField = dateCell.endYearTextField;
            endDateTextField.delegate = self;
            
            if ([_art.interval.suffix isEqualToString:@"CE"]){
                [dateCell.ceButton setSelected:YES];
                [dateCell.bceButton setSelected:NO];
            } else if ([_art.interval.suffix isEqualToString:@"BCE"]){
                [dateCell.ceButton setSelected:NO];
                [dateCell.bceButton setSelected:YES];
            }
            [dateCell configureForArt:_art];
            dateCell.selectedBackgroundView = selectedView;
            [dateCell.label setText:@"DATE"];
            [dateCell.rangeLabel setText:@"DATE RANGE"];
            [dateCell.circaLabel setText:@"CIRCA"];
            [dateCell.singleYearTextField setPlaceholder:@"e.g. 1776"];
            [dateCell.beginYearTextField setPlaceholder:@"Beginning"];
            [dateCell.endYearTextField setPlaceholder:@"End"];
            
            if (_art.interval.year && ![_art.interval.year isEqualToNumber:@0]){
                [dateCell.beginYearTextField setText:[NSString stringWithFormat:@"%@",_art.interval.year]];
                //NSString *suffix = _art.interval.suffix.length ? _art.interval.suffix : @"";
            } else {
                [dateCell.beginYearTextField setText:@""];
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
            [cell.label setText:@"LOCATION"];
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
        case 5:
            [cell.label setText:@"NOTES"];
            [cell.textField setPlaceholder:@"Any miscellaneous notes you may have"];
            [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            notesTextField = cell.textField;
            [cell.textField setText:_art.notes];
            [cell.textField setUserInteractionEnabled:YES];
            break;
        default:
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2){
        return 140.f;
    } else {
        return 50.f;
    }
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

- (void)showIcons {
    WFIconsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Icons"];
    [vc setSelectedIcons:_currentPhoto.icons.mutableCopy];
    vc.iconsDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)iconsSelected:(NSOrderedSet *)selectedIcons {
    _currentPhoto.icons = selectedIcons;
    [self drawPhotosScrollView];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]){
        if (textField == titleTextField){
            [self showArtists];
        } else if (textField == beginDateTextField){
            [endDateTextField becomeFirstResponder];
        } else if (textField == endDateTextField){
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
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue *keyboardValue = keyboardInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
    CGFloat keyboardHeight = convertedKeyboardFrame.size.height;
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
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
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                     }
                     completion:NULL];
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (!_art.interval){
        Interval *interval = [Interval MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [_art setInterval:interval];
    }
    
    if (textField == beginDateTextField || textField == endDateTextField || textField == dateTextField){
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        
        if (textField == beginDateTextField && beginDateTextField.text.length){
            NSNumber *yearNumber = [f numberFromString:beginDateTextField.text];
            if (yearNumber){
                _art.interval.year = yearNumber;
            }
        } else if (textField == endDateTextField && endDateTextField.text.length){
            NSNumber *yearNumber = [f numberFromString:endDateTextField.text];
            if (yearNumber){
                _art.interval.endRange = yearNumber;
            }
        } else if (textField == endDateTextField && endDateTextField.text.length){
            NSNumber *yearNumber = [f numberFromString:endDateTextField.text];
            if (yearNumber){
                _art.interval.year = yearNumber;
            }
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
        }];
        //[_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
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
