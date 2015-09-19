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
#import "WFTagsViewController.h"
#import "Icon+helper.h"
#import "WFCreditTextField.h"
#import "WFUtilities.h"
#import "WFTracking.h"

@interface WFNewArtViewController () <UITableViewDataSource, UITableViewDelegate , UIScrollViewDelegate, UITextFieldDelegate, WFImagePickerControllerDelegate, WFSelectArtistsDelegate, WFSelectLocationsDelegate, WFSelectMaterialsDelegate, WFSelectIconsDelegate, WFSelectTagsDelegate, UIActionSheetDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    BOOL selectingDate;
    CGFloat width;
    CGFloat height;
    UITextField *titleTextField;
    UITextField *dateTextField;
    UITextField *beginDateTextField;
    UITextField *endDateTextField;
    UITextField *materialTextField;
    UITextField *notesTextField;
    UIButton *_eraButton;
    UIButton *_beginEraButton;
    UIButton *_endEraButton;
    NSInteger currentPhotoIdx;
    NSMutableArray *_selectedPhotos;
    CGFloat imageWidth;
    CGFloat imageHeight;
    BOOL keyboardVisible;
    CGFloat topInset;
    UIImageView *navBarShadowView;
    UIActionSheet *eraActionSheet;
    UIActionSheet *beginEraActionSheet;
    UIActionSheet *endEraActionSheet;
}

@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) Photo *currentPhoto;
@property (strong, nonatomic) Art *art;

@end

@implementation WFNewArtViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    width = screenWidth();
    height = screenHeight();
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    imageWidth = 262.f;
    imageHeight = 170.f;
    [self setupSlideContainer];
    self.art = [Art MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
    Interval *interval = [Interval MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
    [self.art setInterval:interval];
    [_photoCountLabel setTextColor:[UIColor colorWithWhite:1 alpha:.33]];
    [_photoCountLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSansLight] size:0]];
    
    if (IDIOM == IPAD){
        [_dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [_submitButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
        [_submitButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
        [_submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_submitButton addTarget:self action:@selector(post) forControlEvents:UIControlEventTouchUpInside];
        _submitButton.layer.cornerRadius = 14.f;
        _submitButton.clipsToBounds = YES;
        
        topInset = 0;
    } else {
        [_dismissButton setHidden:YES];
        UIBarButtonItem *dismissBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismiss)];
        self.navigationItem.leftBarButtonItem = dismissBarButtonItem;
        
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        self.tableView.tableHeaderView = self.headerContainerView;
        topInset = self.navigationController.navigationBar.frame.size.height;
        self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
        navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    }
    
    [self registerKeyboardNotifications];
    
    [_privateLabel setBackgroundColor:[UIColor clearColor]];
    [_privateLabel setTextColor:[UIColor whiteColor]];
    [_privateLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_privateLabel setText:@"MAKE ART PRIVATE"];
    [_privacySwitch addTarget:self action:@selector(switchSwitched:) forControlEvents:UIControlEventValueChanged];
    [_privacySwitch setOn:NO];
    
    self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    
    [WFTracking trackEvent:@"New Art" withProperties:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [ProgressHUD dismiss]; // just in case
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

- (void)didFinishPickingPhotos:(NSMutableArray *)selectedPhotos {
    _selectedPhotos = selectedPhotos;
    for (Photo *p in selectedPhotos){
        Photo *photo = [p MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        [self.art addPhoto:photo];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    if (selectedPhotos.count){
        if (_submitButton.isHidden) [_submitButton setHidden:NO];
        UIBarButtonItem *submitBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add Art" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
        self.navigationItem.rightBarButtonItem = submitBarButtonItem;
    }
    
    [self setPhotoCount];
    [self drawPhotosScrollView];
    self.currentPhoto = self.art.photos.firstObject;
    
    [self dismissViewControllerAnimated:YES completion:^{
        [ProgressHUD dismiss];
    }];
}

- (void)setPhotoCount {
    if (self.art.photos.count == 0) {
        [_photoCountLabel setText:@""];
    } else if (currentPhotoIdx >= self.art.photos.count){
        [_photoCountLabel setText:@"+ more images"];
        [_previousPhotoButton setAlpha:1.0];
        [_previousPhotoButton setEnabled:YES];
        [_nextPhotoButton setAlpha:0.5];
        [_nextPhotoButton setEnabled:NO];
    } else {
        [_photoCountLabel setText:[NSString stringWithFormat:@"%lu of %lu",(unsigned long)currentPhotoIdx + 1,(unsigned long)self.art.photos.count]];
        [_nextPhotoButton setAlpha:1.0];
        [_nextPhotoButton setEnabled:YES];
        if (currentPhotoIdx > 0){
            [_previousPhotoButton setAlpha:1.0];
            [_previousPhotoButton setEnabled:YES];
        } else {
            [_previousPhotoButton setAlpha:.5];
            [_previousPhotoButton setEnabled:NO];
        }
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
            if (currentPhotoIdx < self.art.photos.count){
                self.currentPhoto = self.art.photos[currentPhotoIdx];
            }
            [self setPhotoCount];
        }
    }
}

- (IBAction)nextPhoto:(id)sender{
    [UIView animateWithDuration:.5f delay:0 usingSpringWithDamping:.77 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x + _scrollView.frame.size.width, 0) animated:NO];
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)previousPhoto:(id)sender{
    [UIView animateWithDuration:.5f delay:0 usingSpringWithDamping:.77 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x - _scrollView.frame.size.width, 0) animated:NO];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)drawPhotosScrollView {
    [_scrollView setPagingEnabled:YES];
    _scrollView.delegate = self;
    _scrollView.showsHorizontalScrollIndicator = NO;
    [_scrollView setBackgroundColor:[UIColor clearColor]];
    [_scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.art.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
        WFNewPhotoContainerView *containerView = [[WFNewPhotoContainerView alloc] initWithFrame:CGRectMake(0 + (idx*_scrollView.frame.size.width), 0, _scrollView.frame.size.width, _scrollView.frame.size.height)];
        [containerView setTag:idx];
        [_scrollView addSubview:containerView];
        containerView.photoImageView = [[UIImageView alloc] initWithImage:photo.image];
        [containerView.photoImageView setFrame:CGRectMake(((_scrollView.frame.size.width-imageWidth)/2), 20, imageWidth, imageHeight)];
        [containerView.photoImageView setContentMode:UIViewContentModeScaleAspectFill];
        containerView.photoImageView.clipsToBounds = YES;
        //containerView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        //containerView.layer.shouldRasterize = YES;
        [containerView addSubview:containerView.photoImageView];
        
        containerView.creditLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, containerView.photoImageView.frame.size.height+containerView.photoImageView.frame.origin.y + 6.f, 100, 47)];
        [containerView.creditLabel setText:@"CREDIT / RIGHTS:"];
        [containerView.creditLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSansLight] size:0]];
        [containerView.creditLabel setTextColor:[UIColor lightGrayColor]];
        [containerView addSubview:containerView.creditLabel];
        
        containerView.creditTextField = [[WFCreditTextField alloc] initWithFrame:CGRectMake(containerView.creditLabel.frame.origin.x+containerView.creditLabel.frame.size.width + 3, containerView.photoImageView.frame.size.height+containerView.photoImageView.frame.origin.y + 6.f, 157, 47)];
        containerView.creditTextField.tag = idx;
        containerView.creditTextField.delegate = self;
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3, 43)];
        containerView.creditTextField.leftView = paddingView;
        containerView.creditTextField.leftViewMode = UITextFieldViewModeAlways;
        containerView.creditTextField.rightView = paddingView;
        containerView.creditTextField.rightViewMode = UITextFieldViewModeAlways;
        
        [containerView.creditTextField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.03]];
        [containerView.creditTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
        if (!photo.credit.length){
            [photo setCredit:self.currentUser.fullName];
        }
        [containerView.creditTextField setText:photo.credit];
        [containerView.creditTextField setPlaceholder:@"Photo credit field..."];
        [containerView.creditTextField setTextColor:[UIColor whiteColor]];
        [containerView.creditTextField setTintColor:[UIColor whiteColor]];
        [containerView.creditTextField setTextAlignment:NSTextAlignmentCenter];
        [containerView.creditTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
        [containerView.creditTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [containerView addSubview:containerView.creditTextField];
        
        containerView.iconographyLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, containerView.photoImageView.frame.size.height+containerView.photoImageView.frame.origin.y + 57.f, 100, 47)];
        [containerView.iconographyLabel setText:@"ICONOGRAPHY:"];
        [containerView.iconographyLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSansLight] size:0]];
        [containerView.iconographyLabel setTextColor:[UIColor lightGrayColor]];
        [containerView addSubview:containerView.iconographyLabel];
        
        containerView.iconographyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [containerView.iconographyButton addTarget:self action:@selector(showIcons) forControlEvents:UIControlEventTouchUpInside];
        [containerView.iconographyButton setFrame:CGRectMake(containerView.creditLabel.frame.origin.x+containerView.creditLabel.frame.size.width + 3, containerView.photoImageView.frame.size.height+containerView.photoImageView.frame.origin.y + 57.f, 157, 47)];
        [containerView.iconographyButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.03]];
        [containerView.iconographyButton setTitle:photo.iconsToSentence forState:UIControlStateNormal];
        [containerView.iconographyButton.titleLabel setNumberOfLines:3];
        [containerView.iconographyButton.titleLabel setMinimumScaleFactor:.23f];
        [containerView.iconographyButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
        [containerView addSubview:containerView.iconographyButton];
    }];
    
    [_scrollView addSubview:_addPhotoButton];
    [_scrollView setContentSize:CGSizeMake((self.art.photos.count+1) * _scrollView.frame.size.width, _scrollView.frame.size.height)];
    
    [_addPhotoButton setFrame:CGRectMake(_scrollView.contentSize.width-_scrollView.frame.size.width, 0, _slideContainerView.frame.size.width, _slideContainerView.frame.size.height)];
    [_scrollView bringSubviewToFront:_addPhotoButton];
    
    if (self.art.photos.count){
        [_previousPhotoButton setHidden:NO];
        [_nextPhotoButton setHidden:NO];
    } else {
        [_previousPhotoButton setHidden:YES];
        [_nextPhotoButton setHidden:YES];
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
    NSMutableArray *artistIds = [NSMutableArray arrayWithCapacity:self.art.artists.count];
    for (Artist *artist in self.art.artists){
        [artistIds addObject:artist.identifier];
    }
    [parameters setObject:artistIds forKey:@"artist_ids"];
    
    NSMutableArray *locationIds = [NSMutableArray arrayWithCapacity:self.art.locations.count];
    for (Location *location in self.art.locations){
        [locationIds addObject:location.identifier];
    }
    [parameters setObject:locationIds forKey:@"location_ids"];
    
    NSMutableArray *tagIds = [NSMutableArray arrayWithCapacity:self.art.tags.count];
    for (Tag *tag in self.art.tags){
        [tagIds addObject:tag.identifier];
    }
    [parameters setObject:tagIds forKey:@"tag_ids"];
    
    NSMutableArray *materialIds = [NSMutableArray arrayWithCapacity:self.art.materials.count];
    for (Material *material in self.art.materials){
        [materialIds addObject:material.identifier];
    }
    [parameters setObject:materialIds forKey:@"material_ids"];
    
    if (notesTextField.text.length){
        [parameters setObject:notesTextField.text forKey:@"notes"];
    }
    if (self.art.interval){
        [parameters setObject:self.art.interval.circa forKey:@"interval[circa]"];
        
        if (![self.art.interval.year isEqualToNumber:@0]){
            [parameters setObject:self.art.interval.year forKey:@"interval[year]"];
        }
        if (![self.art.interval.beginRange isEqualToNumber:@0]){
            [parameters setObject:self.art.interval.beginRange forKey:@"interval[begin_range]"];
        }
        if (![self.art.interval.endRange isEqualToNumber:@0]){
            [parameters setObject:self.art.interval.endRange forKey:@"interval[end_range]"];
        }
        if (_eraButton.selected && self.art.interval.suffix.length){
            [parameters setObject:self.art.interval.suffix forKey:@"interval[suffix]"];
        } else {
            [parameters setObject:@"" forKey:@"interval[suffix]"];
        }
        if (_beginEraButton.selected && self.art.interval.beginSuffix.length){
            [parameters setObject:self.art.interval.beginSuffix forKey:@"interval[begin_suffix]"];
        } else {
            [parameters setObject:@"" forKey:@"interval[begin_suffix]"];
        }
        if (_endEraButton.selected && self.art.interval.endSuffix.length){
            [parameters setObject:self.art.interval.endSuffix forKey:@"interval[end_suffix]"];
        } else {
            [parameters setObject:@"" forKey:@"interval[end_suffix]"];
        }
    }

    if ([self.art.privateArt isEqualToNumber:@YES]){
        [parameters setObject:@1 forKey:@"priv"];
    } else {
        [parameters setObject:@0 forKey:@"priv"];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    if (self.artDelegate && [self.artDelegate respondsToSelector:@selector(newArtAdded:)]){
        [self.artDelegate newArtAdded:self.art];
    }
    [ProgressHUD dismiss];
    
    [manager POST:@"arts" parameters:@{@"art":parameters} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSString *userId = [NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
        for (Photo *photo in self.art.photos){
            if (photo.credit.length){
                [formData appendPartWithFormData:[photo.credit dataUsingEncoding:NSUTF8StringEncoding] name:@"photos[][credit]"];
            }
            if ([self.art.privateArt isEqualToNumber:@YES]){
                [photo setPrivatePhoto:@YES];
                [formData appendPartWithFormData:[@"1" dataUsingEncoding:NSUTF8StringEncoding] name:@"photos[][priv]"];
            }
            NSMutableArray *iconIds = [NSMutableArray arrayWithCapacity:photo.icons.count];
            for (Icon *icon in photo.icons){
                [iconIds addObject:icon.identifier];
            }
            [formData appendPartWithFormData:[userId dataUsingEncoding:NSUTF8StringEncoding] name:@"photos[][user_id]"];
            [formData appendPartWithFormData:[[iconIds componentsJoinedByString:@","] dataUsingEncoding:NSUTF8StringEncoding]  name:@"photos[][icon_ids]"];
            
            NSData *imageData = UIImageJPEGRepresentation(photo.image, 1);
            [formData appendPartWithFileData:imageData name:@"photos[][image]" fileName:photo.fileName mimeType:@"image/jpg"];
        }
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success creating art: %@",responseObject);
        [self.art populateFromDictionary:[responseObject objectForKey:@"art"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.artDelegate && [self.artDelegate respondsToSelector:@selector(updateNewArt:)] && ![self.art.privateArt isEqualToNumber:@YES]){
                [self.artDelegate updateNewArt:self.art];
            }
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error creating art: %@",error.description);
        if (self.artDelegate && [self.artDelegate respondsToSelector:@selector(failedToAddArt:)]){
            [self.artDelegate failedToAddArt:self.art];
        }
    }];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .5f * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if ([self.art.privateArt isEqualToNumber:@YES]){
                [WFAlert show:@"We're adding this art to your collection." withTime:3.3f];
            } else {
                [WFAlert show:@"Congratulations! We've added your art to the catalog." withTime:3.3f];
            }
        });
    }];
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
            if (self.art.title.length){
                [cell.textField setText:self.art.title];
            }
            [cell.textField setReturnKeyType:UIReturnKeyNext];
            titleTextField = cell.textField;
            [titleTextField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
            [cell.textField setUserInteractionEnabled:YES];
            break;
        case 1:
            [cell.label setText:@"ARTIST"];
            [cell.textField setPlaceholder:@"Leave blank if artist unknown"];
            [cell.textField setText:self.art.artistsToSentence];
            [cell.textField setReturnKeyType:UIReturnKeyNext];
            [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            [cell.textField setUserInteractionEnabled:NO];
            break;
        case 2:
        {
            WFDateMetadataCell *dateCell = [tableView dequeueReusableCellWithIdentifier:@"DateCell"];
            [dateCell setSelectionStyle:UITableViewCellSelectionStyleNone];
            dateTextField = dateCell.singleYearTextField;
            dateTextField.delegate = self;
            beginDateTextField = dateCell.beginYearTextField;
            beginDateTextField.delegate = self;
            endDateTextField = dateCell.endYearTextField;
            endDateTextField.delegate = self;
            dateCell.selectedBackgroundView = selectedView;
            
            [dateCell configureArt:self.art forEditMode:NO];
            
            [dateCell.circaSwitch setOn:self.art.interval.circa.boolValue animated:YES];
            [dateCell.circaSwitch addTarget:self action:@selector(circaSwitchSwitched:) forControlEvents:UIControlEventValueChanged];
            _eraButton = dateCell.eraButton;
            [dateCell.eraButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            _beginEraButton = dateCell.beginEraButton;
            [dateCell.beginEraButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            _endEraButton = dateCell.endEraButton;
            [dateCell.endEraButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            return dateCell;
        }
            break;
        case 3:
            [cell.label setText:@"LOCATION"];
            [cell.textField setPlaceholder:@"e.g. Paris"];
            [cell.textField setText:self.art.locationsToSentence];
            [cell.textField setUserInteractionEnabled:NO];
            break;
        case 4:
            [cell.label setText:@"TAGS"];
            [cell.textField setPlaceholder:@"e.g. Impressionism, German, etc"];
            [cell.textField setText:self.art.tagsToSentence];
            [cell.textField setUserInteractionEnabled:NO];
            break;
        case 5:
            [cell.label setText:@"MATERIALS"];
            [cell.textField setPlaceholder:@"e.g. clay, wrought iron, etc."];
            [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
            materialTextField = cell.textField;
            [cell.textField setText:self.art.materialsToSentence];
            [cell.textField setUserInteractionEnabled:NO];
            break;
        case 6:
            [cell.label setText:@"NOTES"];
            notesTextField = cell.textField;
            [cell.textField setPlaceholder:@"Any miscellaneous notes you may have"];
            if (self.art.notes.length){
                [cell.textField setText:self.art.notes];
            }
            [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            [cell.textField setText:self.art.notes];
            [cell.textField setUserInteractionEnabled:YES];
            break;
        default:
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2){
        if (IDIOM == IPAD){
            return 100.f;
        } else {
            return 150.f;
        }
    } else {
        if (IDIOM == IPAD){
            return 50.f;
        } else {
            return 74.f;
        }
    }
}

- (void)eraTapped:(UIButton*)button {
    if (button == _eraButton){
        eraActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"CE",@"BCE",@"Clear",nil];
        [eraActionSheet showInView:self.view];
    } else if (button == _beginEraButton){
        beginEraActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"CE",@"BCE",@"Clear",nil];
        [beginEraActionSheet showInView:self.view];
    } else if (button == _endEraButton){
        endEraActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"CE",@"BCE",@"Clear",nil];
        [endEraActionSheet showInView:self.view];
    }
}

- (void)circaSwitchSwitched:(UISwitch*)circaSwitch {
    self.art.interval.circa = [NSNumber numberWithBool:circaSwitch.isOn];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        
    }];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == eraActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"CE"]){
            [_eraButton setTitle:@"CE" forState:UIControlStateNormal];
            [self.art.interval setSuffix:@"CE"];
            [_eraButton setSelected:YES];
            [_eraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"BCE"]){
            [_eraButton setTitle:@"BCE" forState:UIControlStateNormal];
            [self.art.interval setSuffix:@"BCE"];
            [_eraButton setSelected:YES];
            [_eraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Clear"]) {
            [_eraButton setTitle:@"CE" forState:UIControlStateNormal];
            [_eraButton setSelected:NO];
            [_eraButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
            [self.art.interval setSuffix:nil];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
        }];
    } else if (actionSheet == beginEraActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"CE"]){
            [_beginEraButton setTitle:@"CE" forState:UIControlStateNormal];
            [self.art.interval setBeginSuffix:@"CE"];
            [_beginEraButton setSelected:YES];
            [_beginEraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"BCE"]) {
            [_beginEraButton setTitle:@"BCE" forState:UIControlStateNormal];
            [self.art.interval setBeginSuffix:@"BCE"];
            [_beginEraButton setSelected:YES];
            [_beginEraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Clear"])  {
            [_beginEraButton setTitle:@"CE" forState:UIControlStateNormal];
            [_beginEraButton setSelected:NO];
            [_beginEraButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
            [self.art.interval setBeginSuffix:nil];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
        }];
    } else if (actionSheet == endEraActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"CE"]){
            [_endEraButton setTitle:@"CE" forState:UIControlStateNormal];
            [self.art.interval setEndSuffix:@"CE"];
            [_endEraButton setSelected:YES];
            [_endEraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"BCE"]) {
            [_endEraButton setTitle:@"BCE" forState:UIControlStateNormal];
            [_endEraButton setSelected:YES];
            [self.art.interval setEndSuffix:@"BCE"];
            [_endEraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Clear"])  {
            [_endEraButton setTitle:@"CE" forState:UIControlStateNormal];
            [_endEraButton setSelected:NO];
            [_endEraButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
            [self.art.interval setEndSuffix:nil];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
        }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1){
        [self showArtists];
    } else if (indexPath.row == 3){
        [self showLocations];
    } else if (indexPath.row == 4){
        [self showTags];
    } else if (indexPath.row == 5){
        [self showMaterials];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showArtists {
    WFArtistsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Artists"];
    [vc setSelectedArtists:self.art.artists.mutableCopy];
    vc.artistDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)artistsSelected:(NSOrderedSet *)selectedArtists {
    self.art.artists = selectedArtists;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showLocations {
    WFLocationsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Locations"];
    [vc setSelectedLocations:self.art.locations.mutableCopy];
    vc.locationDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)locationsSelected:(NSOrderedSet *)selectedLocations {
    self.art.locations = selectedLocations;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showTags {
    WFTagsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Tags"];
    [vc setSelectedTags:self.art.tags.mutableCopy];
    vc.tagDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)tagsSelected:(NSOrderedSet *)selectedTags {
    self.art.tags = selectedTags;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:4 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showMaterials {
    WFMaterialsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Materials"];
    [vc setSelectedMaterials:self.art.materials.mutableCopy];
    vc.materialDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)materialsSelected:(NSOrderedSet *)selectedMaterials {
    self.art.materials = selectedMaterials;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:5 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showIcons {
    WFIconsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Icons"];
    [vc setSelectedIcons:self.currentPhoto.icons.mutableCopy];
    vc.iconsDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)iconsSelected:(NSOrderedSet *)selectedIcons {
    self.currentPhoto.icons = selectedIcons;
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
    [self.art setPrivateArt:thisSwitch.isOn ? @YES : @NO];
}

- (void)showPhotoLibrary {
    
}

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)willShowKeyboard:(NSNotification*)notification {
    keyboardVisible = YES;
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
                         self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, keyboardHeight+70.f, 0); // random bottom spacer
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, keyboardHeight+70.f, 0); // random bottom spacer
                     }
                     completion:^(BOOL finished) {

                     }];
}

- (void)willHideKeyboard:(NSNotification *)notification {
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    keyboardVisible = NO;
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, 0, 0);
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == titleTextField){
        self.art.title = titleTextField.text;
    } else if (textField == notesTextField){
        self.art.notes = notesTextField.text;
    } else if (textField == beginDateTextField || textField == endDateTextField || textField == dateTextField){
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        
        if (textField == beginDateTextField && beginDateTextField.text.length){
            NSNumber *yearNumber = [f numberFromString:beginDateTextField.text];
            if (yearNumber){
                self.art.interval.beginRange = yearNumber;
            }
        } else if (textField == endDateTextField && endDateTextField.text.length){
            NSNumber *yearNumber = [f numberFromString:endDateTextField.text];
            if (yearNumber){
                self.art.interval.endRange = yearNumber;
            }
        } else if (textField == dateTextField && dateTextField.text.length){
            NSNumber *yearNumber = [f numberFromString:dateTextField.text];
            if (yearNumber){
                self.art.interval.year = yearNumber;
            }
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
        }];
    } else if ([textField isKindOfClass:[WFCreditTextField class]] && textField.text.length){
        Photo *photo = self.art.photos[textField.tag];
        [photo setCredit:textField.text];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        
    }];
}

- (void)dismiss {
    if (keyboardVisible){
        [self.view endEditing:YES];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
