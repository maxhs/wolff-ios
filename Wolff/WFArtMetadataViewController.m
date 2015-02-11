//
//  WFArtMetadataViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFAppDelegate.h"
#import "WFArtMetadataViewController.h"
#import "WFArtMetadataCell.h"
#import "WFCatalogViewController.h"
#import "Institution+helper.h"
#import "Favorite+helper.h"
#import "Location+helper.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIButton+WebCache.h>
#import "WFLightTablesViewController.h"
#import "WFAlert.h"
#import "WFComparisonViewController.h"
#import "WFSlideshowFocusAnimator.h"
#import "WFLoginAnimator.h"
#import "WFLoginViewController.h"
#import "WFFlagViewController.h"
#import "WFProfileAnimator.h"
#import "WFProfileViewController.h"
#import "WFArtistsViewController.h"
#import "WFLocationsViewController.h"

@interface WFArtMetadataViewController () <UITextViewDelegate, UIPopoverControllerDelegate, UIAlertViewDelegate, UIViewControllerTransitioningDelegate, WFLightTablesDelegate, WFLoginDelegate, WFSelectArtistsDelegate, WFSelectLocationsDelegate, UIActionSheetDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    BOOL iOS8;
    NSDateFormatter *dateFormatter;
    User *_currentUser;
    Favorite *_favorite;
    BOOL editMode;
    BOOL login;
    BOOL profile;
    CGFloat keyboardHeight;
    UITextView *titleTextView;
    UITextView *notesTextView;
    UISwitch *privateSwitch;
    CGRect originalViewFrame;
    UIView *saveContainerView;
    UIButton *saveButton;
    UIImageView *navBarShadowView;
    CGFloat rowHeight;
    CGFloat textViewWidth;
    NSInteger currentPhoto;
}
@property (strong, nonatomic) UIPopoverController *popover;
@end

@implementation WFArtMetadataViewController

@synthesize photo = _photo;

- (void)viewDidLoad {
    [super viewDidLoad];
    if (SYSTEM_VERSION >= 8.f){
        iOS8 = YES;
    } else {
        iOS8 = NO;
    }
    self.automaticallyAdjustsScrollViewInsets = NO;
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    rowHeight = 60.f;
    textViewWidth = self.view.frame.size.width - 160.f; // 160.f is a spacer
    editMode = NO;
    [self setupDateFormatter];
    [self registerForKeyboardNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadPhotoMetadata];
    [self setupHeader];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    originalViewFrame = self.view.frame;
}

- (void)setupDateFormatter {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
}

- (void)setupHeader {
    self.tableView.tableHeaderView = _topImageContainerView;
    [self setupPhotoScrollView];
    [_backButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self setUpButtons];
    
    [_nextPhotoButton addTarget:self action:@selector(nextPhoto) forControlEvents:UIControlEventTouchUpInside];
    [_lastPhotoButton addTarget:self action:@selector(lastPhoto) forControlEvents:UIControlEventTouchUpInside];
    [_photoCountLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [self setPhotoCount];
}

- (void)setPhotoCount{
    if (_photo.art.photos.count == 1){
        [_photoCountLabel setText:@"1 photo"];
    } else {
    NSInteger currentIdx = [_photo.art.photos indexOfObject:_photo] + 1;
        [_photoCountLabel setText:[NSString stringWithFormat:@"%ld of %lu photos",(long)currentIdx, (unsigned long)_photo.art.photos.count]];
    }
    [self setPhotoCredit];
}

- (void)setupPhotoScrollView {
    [_photoScrollView setBackgroundColor:[UIColor clearColor]];
    _photoScrollView.delegate = self;
    _photoScrollView.pagingEnabled = YES;
    CGFloat imageWidth = 360.f;
    CGFloat imageHeight = 360.f;
    [_photoScrollView setContentSize:CGSizeMake(_photo.art.photos.count*imageWidth, imageHeight)];
    [_photoScrollView setCanCancelContentTouches:YES];
    
    NSInteger idx = 0;
    for (Photo *photo in _photo.art.photos){
        
        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [imageButton setShowsTouchWhenHighlighted:NO];
        [imageButton setAdjustsImageWhenHighlighted:NO];
        [imageButton setBackgroundColor:kSlideBackgroundColor];
        imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageButton.imageView.layer.cornerRadius = 3.f;
        imageButton.imageView.layer.backgroundColor = [UIColor clearColor].CGColor;
        [imageButton setFrame:CGRectMake(0+(idx*imageWidth), 0, imageWidth, imageHeight)];
        [_photoScrollView addSubview:imageButton];
        
        if (!imageButton.imageView.image){
            [imageButton setAlpha:0.0];
        }
        
        [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:photo.mediumImageUrl] options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            [_progressIndicator setProgress:((CGFloat)receivedSize / (CGFloat)expectedSize)];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            [imageButton setImage:image forState:UIControlStateNormal];
            [UIView animateWithDuration:.23 animations:^{
                [imageButton setAlpha:1.0];
            } completion:^(BOOL finished) {
                //[imageButton.imageView.layer setShouldRasterize:YES];
                //imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            }];
        }];
        [imageButton addTarget:self action:@selector(showFullScreen) forControlEvents:UIControlEventTouchUpInside];
        idx ++;
    }
}

- (void)setPhotoCredit {
    if (_photo.credit.length){
        [_creditButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
        [_creditButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
        [_creditButton setTitle:[NSString stringWithFormat:@"Credit: %@",_photo.credit] forState:UIControlStateNormal];
        [_creditButton addTarget:self action:@selector(showProfile) forControlEvents:UIControlEventTouchUpInside];
        [_creditButton setHidden:NO];
        [_creditButton.titleLabel setNumberOfLines:0];
    } else {
        [_creditButton setHidden:YES];
    }
}

- (void)nextPhoto {
    [_photoScrollView setContentOffset:CGPointMake(_photoScrollView.contentOffset.x+360.f, 0) animated:YES];
    [self setPhotoCount];
}

- (void)lastPhoto {
    [_photoScrollView setContentOffset:CGPointMake(_photoScrollView.contentOffset.x-360.f, 0) animated:YES];
    [self setPhotoCount];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentSizeWidth = scrollView.frame.size.width;
    CGFloat offsetX = scrollView.contentOffset.x;
    float fractionalPage = offsetX / contentSizeWidth;
    NSInteger page = lround(fractionalPage);
    if (currentPhoto != page) {
        currentPhoto = page;
        Art *art = _photo.art;
        if (currentPhoto <= art.photos.count - 1){
            _photo = art.photos[currentPhoto];
            [self setPhotoCount];
        }
    }
}

- (void)setUpButtons {
    [_flagButton addTarget:self action:@selector(presentFlagActionSheet) forControlEvents:UIControlEventTouchUpInside];
    [_flagButton setImage:[UIImage imageNamed:@"flag"] forState:UIControlStateNormal];
    [_flagButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
    [_flagButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    
    [_dropToTableButton addTarget:self action:@selector(dropToLightTable) forControlEvents:UIControlEventTouchUpInside];
    [_dropToTableButton setImage:[UIImage imageNamed:@"dropToLightTable"] forState:UIControlStateNormal];
    [_dropToTableButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
    [_dropToTableButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    
    if (_currentUser && [_photo.user.identifier isEqualToNumber:_currentUser.identifier]){
        [_editButton addTarget:self action:@selector(edit) forControlEvents:UIControlEventTouchUpInside];
        [_editButton setImage:[UIImage imageNamed:@"edit"] forState:UIControlStateNormal];
        [_editButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
        [_editButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
        [_editButton setHidden:NO];
        
        [_deleteButton addTarget:self action:@selector(confirmDeletion) forControlEvents:UIControlEventTouchUpInside];
        [_deleteButton setImage:[UIImage imageNamed:@"trash"] forState:UIControlStateNormal];
        [_deleteButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
        [_deleteButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
        [_deleteButton setHidden:NO];
        
        saveContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 70)];
        [saveContainerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [saveContainerView setBackgroundColor:[UIColor whiteColor]];
        
        saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [saveContainerView addSubview:saveButton];
        [saveButton setFrame:CGRectMake(10, 13, saveContainerView.frame.size.width-20, 44)];
        [saveButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansSemibold] size:0]];
        [saveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [saveButton addTarget:self action:@selector(saveMetadata) forControlEvents:UIControlEventTouchUpInside];
        [saveButton setTitle:@"SAVE" forState:UIControlStateNormal];
        saveButton.layer.cornerRadius = 7.f;
        [saveButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.1]];
        
    } else {
        [_editButton setHidden:YES];
        [_deleteButton setHidden:YES];
    }
    
    [_favoriteButton setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
    [_favoriteButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    _favorite = [_currentUser getFavoritePhoto:_photo];
    if (_currentUser && _favorite){
        [_favoriteButton setTitle:@"   Favorited!" forState:UIControlStateNormal];
        [_favoriteButton addTarget:self action:@selector(unfavorite) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [_favoriteButton addTarget:self action:@selector(favorite) forControlEvents:UIControlEventTouchUpInside];
        [_favoriteButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
    }
}

- (void)dropToLightTable {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    WFLightTablesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"LightTables"];
    vc.lightTableDelegate = self;
    [vc setPhoto:_photo];
    [vc setLightTables:_currentUser.lightTables.array.mutableCopy];
    CGFloat vcHeight = _currentUser.lightTables.count*54.f > 260.f ? 260 : (_currentUser.lightTables.count)*54.f;
    vc.preferredContentSize = CGSizeMake(420, vcHeight+34.f); // add the header height
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    [self.popover presentPopoverFromRect:CGRectMake(_dropToTableButton.center.x,(_dropToTableButton.center.y+_dropToTableButton.frame.size.height/2)+ 23,1,1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES]; // added 23 points to the popover rect to make the arrow look nicerp 
}

- (void)lightTableSelected:(NSNumber *)lightTableId {
    //refetch the light table
    Table *lightTable = [Table MR_findFirstByAttribute:@"identifier" withValue:lightTableId inContext:[NSManagedObjectContext MR_defaultContext]];
    [lightTable addPhoto:_photo];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    //ensure we're playing with a real light table first
    if (![lightTable.identifier isEqualToNumber:@0]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:_photo.identifier forKey:@"photo_id"];
        [manager POST:[NSString stringWithFormat:@"light_tables/%@/add",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success dropping metadata photo to light table: %@",responseObject);
            if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToNumber:@1]){
                
                if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(droppedPhoto:toLightTable:)]){
                    [self.metadataDelegate droppedPhoto:_photo toLightTable:lightTable];
                }
            } else {
                [WFAlert show:@"Something went wrong while trying to drop this art to your light table. Please try again soon" withTime:3.3f];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to drop metadata photo to light table: %@",error.description);
        }];
    }
}

- (void)undropPhotoFromLightTable:(NSNumber *)lightTableId {
    //refetch the light table
    Table *lightTable = [Table MR_findFirstByAttribute:@"identifier" withValue:lightTableId inContext:[NSManagedObjectContext MR_defaultContext]];
    [lightTable removePhoto:_photo];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self setUpButtons];
    
    //ensure we're playing with a real light table first
    if (![lightTable.identifier isEqualToNumber:@0]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:_photo.identifier forKey:@"photo_id"];
        [manager DELETE:[NSString stringWithFormat:@"light_tables/%@/remove",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success UNdropping metadata photo to light table: %@",responseObject);
            if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToNumber:@1]){
                if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(removedPhoto:fromLightTable:)]){
                    [self.metadataDelegate removedPhoto:_photo fromLightTable:lightTable];
                }
            } else {
                [WFAlert show:@"Something went wrong while trying to drop this art to your light table. Please try again soon" withTime:3.3f];
            }
            [ProgressHUD dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to drop metadata photo to light table: %@",error.description);
            [ProgressHUD dismiss];
        }];
    }
}

- (void)edit {
    editMode = editMode ? NO : YES;
    [self.tableView reloadData];
    if (editMode){
        CGRect newViewFrame = originalViewFrame;
        if (iOS8){
            newViewFrame.origin.y = 10;
            newViewFrame.origin.x -= 100;
            newViewFrame.size.width += 200;
        } else {
            newViewFrame.origin.x = 10;
            newViewFrame.origin.y -= 100;
            newViewFrame.size.height += 200;
        }
        self.tableView.tableFooterView = saveContainerView;
        [UIView animateWithDuration:.77 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.view setFrame:newViewFrame];
            if (iOS8){
                [saveButton setFrame:CGRectMake(20, 13, newViewFrame.size.width-40, 44)];
            } else {
                [saveButton setFrame:CGRectMake(20, 13, newViewFrame.size.height-40, 44)];
            }
        } completion:^(BOOL finished) {
            
        }];
        
        [self.view endEditing:YES];
        double delayInSeconds = .23;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [titleTextView becomeFirstResponder];
        });
    } else {
        // temporarily set the tableView background color to white so that the cell backgrounds don't get exposed
        [self.tableView setBackgroundColor:[UIColor whiteColor]];
        [UIView animateWithDuration:.77 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.view setFrame:originalViewFrame];
            self.tableView.tableFooterView = nil;
        } completion:^(BOOL finished) {
            [self.tableView setBackgroundColor:[UIColor clearColor]];
        }];
    }
}

- (void)loginSuccessful {
    NSLog(@"Login Successful.");
    [self setUpButtons];
}

- (void)showProfile {
    WFProfileViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
    [vc setUser:_photo.user];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)loadPhotoMetadata {
    [manager GET:[NSString stringWithFormat:@"photos/%@",_photo.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success fetching metadata: %@",responseObject);
        if ([responseObject objectForKey:@"text"] && [[responseObject objectForKey:@"text"] isEqualToString:kNoPhoto]){
            [_photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            [WFAlert show:@"Sorry, but something went wrong while trying to fetch this art.\n\nThe creator likely expunged it from our database." withTime:3.7f];
            [self dismiss];
            if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(photoDeleted:)]){
                [self.metadataDelegate photoDeleted:_photo.identifier];
            }
        } else {
            [_photo populateFromDictionary:[responseObject objectForKey:@"photo"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [self setupHeader];
                [self.tableView reloadData];
            }];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching art metadata: %@",error.description);
    }];
}

- (void)saveMetadata {
    _photo.art.notes = notesTextView.text;
    _photo.art.title = titleTextView.text;
    [ProgressHUD show:@"Saving..."];
    [self.view endEditing:YES];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:_photo.art.title forKey:@"title"];
    [parameters setObject:_photo.art.notes forKey:@"notes"];
    [parameters setObject:@(privateSwitch.isOn) forKey:@"private"];
    [manager PATCH:[NSString stringWithFormat:@"arts/%@",_photo.art.identifier] parameters:@{@"art":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success saving metadata: %@",responseObject);
        [_photo.art populateFromDictionary:[responseObject objectForKey:@"art"]];
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD dismiss];
            [WFAlert show:@"Saved" withTime:2.3f];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error saving metadata: %@",error.description);
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD dismiss];
            [WFAlert show:@"Something went wrong while trying to save your changes. Please try again soon." withTime:3.3f];
        }];
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (iOS8){
        textViewWidth = self.view.frame.size.width - 160.f; // 160.f is a spacer
    } else {
        textViewWidth = self.view.frame.size.height - 160.f; // 160.f is a spacer
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (editMode){
        return 9;
    } else {
        return 8;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFArtMetadataCell *cell = (WFArtMetadataCell *)[tableView dequeueReusableCellWithIdentifier:@"ArtMetadataCell"];
    [cell setDefaultStyle:editMode];
    cell.textView.delegate = self;
    [cell.textView setKeyboardAppearance:UIKeyboardAppearanceDark];
    [cell.textView setUserInteractionEnabled:YES];
    
    switch (indexPath.row) {
        case 0:
            [cell.label setText:@"TITLE"];
            [cell.textView setText:_photo.art.title];
            titleTextView = cell.textView;
            break;
        case 1:
        {
            [cell.label setText:@"ARTIST(S)"];
            NSString *artists = [_photo.art artistsToSentence];
            if (artists.length > 0){
                [cell.textView setText:artists];
            } else {
                [cell.textView setText:@"Artist(s) Unknown"];
                [cell.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textView setTextColor:[UIColor lightGrayColor]];
            }
            [cell.textView setUserInteractionEnabled:NO];
        }
            break;
        case 2:
            [cell.label setText:@"DATE"];
            if (_photo.art.interval.single){
                [cell.textView setText:[dateFormatter stringFromDate:_photo.art.interval.single]];
            } else if (_photo.art.interval.beginRange && ![_photo.art.interval.beginRange isEqualToNumber:@0] && _photo.art.interval.endRange && ![_photo.art.interval.endRange isEqualToNumber:@0]) {
                NSString *beginSuffix = _photo.art.interval.beginSuffix.length ? _photo.art.interval.beginSuffix : @"CE";
                NSString *endSuffix = _photo.art.interval.endSuffix.length ? _photo.art.interval.endSuffix : @"CE";
                [cell.textView setText:[NSString stringWithFormat:@"%@ %@ - %@ %@",_photo.art.interval.beginRange, beginSuffix, _photo.art.interval.endRange, endSuffix]];
            } else if (_photo.art.interval.year && ![_photo.art.interval.year isEqualToNumber:@0]){
                NSString *suffix = _photo.art.interval.suffix.length ? _photo.art.interval.suffix : @"CE";
                [cell.textView setText:[NSString stringWithFormat:@"%@ %@",_photo.art.interval.year, suffix]];
            } else {
                [cell.textView setText:@"No date listed"];
                [cell.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textView setTextColor:[UIColor lightGrayColor]];
            }
            [cell.textView setKeyboardType:UIKeyboardTypeNumberPad];
            break;
        case 3:
        {
            [cell.label setText:@"LOCATION"];
            NSString *locations = [_photo.art locationsToSentence];
            
            if (locations.length){
                [cell.textView setText:locations];
            } else {
                [cell.textView setText:@"No locations listed"];
                [cell.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textView setTextColor:[UIColor lightGrayColor]];
            }
            [cell.textView setUserInteractionEnabled:NO];
        }
            break;
        case 4:
        {
            [cell.label setText:@"MATERIAL(S)"];
            NSString *materials = [_photo.art materialsToSentence];
            if (materials.length){
                [cell.textView setText:materials];
            } else {
                [cell.textView setText:@"No materials listed"];
                [cell.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textView setTextColor:[UIColor lightGrayColor]];
            }
        }
            break;
        case 5:
        {
            [cell.label setText:@"ICONOGRAPHY"];
            NSString *icons = [_photo.art iconsToSentence];
            if (icons.length){
                [cell.textView setText:icons];
            } else {
                [cell.textView setText:@"N/A"];
                [cell.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textView setTextColor:[UIColor lightGrayColor]];
            }
        }
            break;
        case 6:
            [cell.label setText:@"CREDIT"];
            [cell.textView setText:(_photo.credit.length ? _photo.credit : _photo.user.fullName)];
            break;
        case 7:
            [cell.label setText:@"NOTES"];
            [cell.textView setText:@""];
            notesTextView = cell.textView;
            CGRect notesRect = cell.textView.frame;
            CGFloat cellHeight = cell.frame.size.height;
            CGFloat minHeight = cellHeight-14 > 86 ? cellHeight-14 : 86;
            notesRect.origin.y = 12.f;
            notesRect.size.height = minHeight;
            [cell.textView setFrame:notesRect];
            [cell.textView setText:_photo.art.notes];
            break;
        case 8:
            [cell.label setText:@"PRIVATE"];
            [cell.privateSwitch setHidden:NO];
            privateSwitch = cell.privateSwitch;
            [privateSwitch setOn:_photo.art.privateArt.boolValue];
            [cell.textView setHidden:YES];
            break;
            
        default:
            break;
    }
    
    if (indexPath.row != 7){
        [cell.textView sizeToFit];
        CGRect textViewRect = cell.textView.frame;
        textViewRect.size.width = textViewWidth;
        CGFloat comparisonHeight = cell.frame.size.height > rowHeight ? cell.frame.size.height : rowHeight;
        textViewRect.origin.y = comparisonHeight/2-textViewRect.size.height/2;
        [cell.textView setFrame:textViewRect];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 3){
        UITextView *sizingTextView = [[UITextView alloc] init];
        [sizingTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
        [sizingTextView setText:_photo.art.materialsToSentence];
        CGSize size = [sizingTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        CGFloat newRowHeight = size.height > rowHeight ? size.height : rowHeight;
        sizingTextView = nil;
        return newRowHeight;
    } else if (indexPath.row == 4){
        UITextView *sizingTextView = [[UITextView alloc] init];
        [sizingTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
        [sizingTextView setText:_photo.art.iconsToSentence];
        CGSize size = [sizingTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        CGFloat newRowHeight = size.height > rowHeight ? size.height : rowHeight;
        sizingTextView = nil;
        return newRowHeight;
    } else if (indexPath.row == 5){
        UITextView *sizingTextView = [[UITextView alloc] init];
        [sizingTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
        [sizingTextView setText:_photo.art.locationsToSentence];
        CGSize size = [sizingTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        CGFloat newRowHeight = size.height > rowHeight ? size.height : rowHeight;
        sizingTextView = nil;
        return newRowHeight;
    } else if (indexPath.row == 6){
        UITextView *sizingTextView = [[UITextView alloc] init];
        [sizingTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
        [sizingTextView setText:_photo.credit];
        CGSize size = [sizingTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        CGFloat newRowHeight = size.height > rowHeight ? size.height : rowHeight;
        sizingTextView = nil;
        return newRowHeight;
    } else if (indexPath.row == 7) {
        return 124;
    } else {
        return rowHeight;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1){
        [self showArtists];
    } else if (indexPath.row == 3){
        [self showLocations];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showArtists {
    WFArtistsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Artists"];
    [vc setSelectedArtists:_photo.art.artists.mutableCopy];
    vc.artistDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)artistsSelected:(NSOrderedSet *)selectedArtists {
    _photo.art.artists = selectedArtists;
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showLocations {
    WFLocationsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Locations"];
    [vc setSelectedLocations:_photo.art.locations.mutableCopy];
    vc.locationDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)locationsSelected:(NSOrderedSet *)selectedLocations {
    _photo.art.locations = selectedLocations;
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)favorite {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [manager POST:[NSString stringWithFormat:@"photos/%@/favorite",_photo.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success posting favorite: %@",responseObject);
            _favorite = [Favorite MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [_favorite populateFromDictionary:[responseObject objectForKey:@"favorite"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [_favoriteButton setTitle:@"   Favorited!" forState:UIControlStateNormal];
                [_favoriteButton removeTarget:nil
                                       action:NULL
                             forControlEvents:UIControlEventAllEvents];
                [_favoriteButton addTarget:self action:@selector(unfavorite) forControlEvents:UIControlEventTouchUpInside];
                if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(favoritedPhoto:)]){
                    [self.metadataDelegate favoritedPhoto:_photo];
                }
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to favorite %@: %@",_photo.art.title,error.description);
        }];
    } else {
        [self showLogin];
    }
}

- (void)unfavorite {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && _favorite){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [manager DELETE:[NSString stringWithFormat:@"favorites/%@",_favorite.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success deleting favorite: %@",responseObject);
            [_favorite MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            _favorite = nil;
            
            [_favoriteButton setTitle:@"    Add to favorites" forState:UIControlStateNormal];
            [_favoriteButton removeTarget:nil
                                   action:NULL
                         forControlEvents:UIControlEventAllEvents];
            [_favoriteButton addTarget:self action:@selector(favorite) forControlEvents:UIControlEventTouchUpInside];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to unfavorite %@: %@",_photo.art.title,error.description);
        }];
    } else {
        [self showLogin];
    }
}

- (void)showLogin {
    WFLoginViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
    delegate.loginDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    vc.transitioningDelegate = self;
    login = YES;
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

- (void)showFullScreen {
    WFComparisonViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Comparison"];
    [vc setPhotos:[NSMutableOrderedSet orderedSetWithObject:_photo]];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)presentFlagActionSheet {
    UIActionSheet *flagActionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Why do you want to flag \"%@\"?",_photo.art.title] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Inappropriate", @"Copyright", @"Incorrect metadata", nil];
    
    flagActionSheet.tintColor = kElectricBlue;
    [flagActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Inappropriate"]){
        [self flag];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Copyright"]) {
        [self flag];
        /*WFFlagViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Flag"];
        [vc setCopyright:YES];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:^{
            
        }];*/
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Incorrect metadata"]) {
        [self flag];
        /*WFFlagViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Flag"];
        [vc setCopyright:NO];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:^{
            
        }];*/
    }
}

- (void)flag {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:_photo.identifier forKey:@"photo_id"];
    [parameters setObject:_photo.art.identifier forKey:@"art_id"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    [parameters setObject:@1 forKey:@"code"];
    [manager POST:[NSString stringWithFormat:@"flags"] parameters:@{@"flag":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a flag for %@, %@",_photo.identifier, responseObject);
        [WFAlert show:@"Flagged" withTime:2.3f];
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
        if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(artFlagged:)]){
            [self.metadataDelegate artFlagged:_photo.art];
        }
        [self dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to create a flag: %@",error.description);
        [WFAlert show:@"Sorry, but something went wrong while trying to flag this art. Please try again soon." withTime:3.3f];
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
    }];
}

- (void)confirmDeletion {
    [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to delete this art? This can not be undone." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [ProgressHUD show:@"Deleting..."];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [manager DELETE:[NSString stringWithFormat:@"photos/%@",_photo.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success deleting photo: %@",responseObject);
            NSNumber *photoId = _photo.identifier;
            [_photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
                if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(photoDeleted:)]){
                    [self.metadataDelegate photoDeleted:photoId];
                }
                [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                    [WFAlert show:@"Art expunged" withTime:2.7f];
                }];
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to delete a photo: %@",error.description);
            [WFAlert show:@"Sorry, but something went wrong while trying to remove this art.\n\nMaybe this is the Universe saying something..." withTime:3.3f];
            [ProgressHUD dismiss];
        }];
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
                         // offset by keyboard height plus part of the height of the save button
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight+34, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight+34, 0);
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

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (textView == titleTextView){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    
}

#pragma mark Dismiss & Transition Methods
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    if (login){
        WFLoginAnimator *animator = [WFLoginAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (profile){
        WFProfileAnimator *animator = [WFProfileAnimator new];
        animator.presenting = YES;
        return animator;
    } else {
        WFSlideshowFocusAnimator *animator = [WFSlideshowFocusAnimator new];
        animator.presenting = YES;
        return animator;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if (login){
        WFSlideshowFocusAnimator *animator = [WFSlideshowFocusAnimator new];
        return animator;
    } else if (profile){
        NSLog(@"profile animator dismiss");
        WFProfileAnimator *animator = [WFProfileAnimator new];
        return animator;
    } else {
        WFLoginAnimator *animator = [WFLoginAnimator new];
        return animator;
    }
}

- (void)dismiss {
    if (editMode){
        [self.view endEditing:YES];
        [self edit];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
