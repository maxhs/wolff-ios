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
#import <AFNetworking/UIButton+AFNetworking.h>
#import "WFLightTableDetailsViewController.h"
#import "WFLightTablesViewController.h"
#import "WFAlert.h"
#import "WFSlideshowViewController.h"
#import "WFSlideshowFocusAnimator.h"
#import "WFLoginAnimator.h"
#import "WFLoginViewController.h"
#import "WFFlagViewController.h"
#import "WFProfileAnimator.h"
#import "WFProfileViewController.h"
#import "WFArtistsViewController.h"
#import "WFLocationsViewController.h"
#import "WFTagsViewController.h"
#import "Art+helper.h"
#import "WFMaterialsViewController.h"
#import "WFIconsViewController.h"
#import "WFDateMetadataCell.h"
#import "WFMetadataModalAnimator.h"
#import "Icon+helper.h"
#import "WFNoRotateNavController.h"
#import "WFNewLightTableAnimator.h"
#import "WFTransparentBGModalAnimator.h"
#import "WFPartnerProfileViewController.h"

NSString* const unfavoriteOption = @"Unfavorite";
NSString* const favoriteOption = @"Favorite";
NSString* const tagOption = @"Tag";
NSString* const lightTableOption = @"Drop to light table";
NSString* const flagOption = @"Flag";
NSString* const editOption = @"Edit";
NSString* const communityEditOption = @"Community Edit";
NSString* const deleteOption = @"Delete";

@interface WFArtMetadataViewController () <UITextViewDelegate, UIPopoverControllerDelegate, UIAlertViewDelegate, UIViewControllerTransitioningDelegate, WFLightTablesDelegate, WFLightTableDelegate, WFLoginDelegate, WFSelectArtistsDelegate, WFSelectLocationsDelegate, WFSelectIconsDelegate, WFSelectMaterialsDelegate, WFSelectTagsDelegate, UIActionSheetDelegate, UITextFieldDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    NSDateFormatter *dateFormatter;
    BOOL editMode;
    BOOL keyboardUp;
    BOOL login;
    BOOL profile;
    BOOL newLightTableTransition;
    BOOL metadataModal;
    BOOL lightTables;
    CGFloat keyboardHeight;
    UITextView *titleTextView;
    UITextView *artistTextView;
    UITextView *dateTextView;
    UITextView *locationTextView;
    UITextView *materialTextView;
    UITextView *iconographyTextView;
    UITextView *notesTextView;
    UITextView *creditTextView;
    UITextView *tagsTextView;
    UISwitch *privateSwitch;
    CGRect originalViewFrame;
    CGRect originalNavFrame;
    UIView *saveContainerView;
    UIButton *saveButton;
    UIImageView *navBarShadowView;
    NSInteger currentPhotoIdx;
    UITextField *beginYearTextField;
    UITextField *endYearTextField;
    UITextField *dateTextField;
    UIButton *_eraButton;
    UIButton *_beginEraButton;
    UIButton *_endEraButton;
    UIBarButtonItem *moreButton;
    UIBarButtonItem *saveBarButton;
    UIActionSheet *flagActionSheet;
    UIActionSheet *eraActionSheet;
    UIActionSheet *beginEraActionSheet;
    UIActionSheet *endEraActionSheet;
}
@property (strong, nonatomic) AFHTTPRequestOperation *mainRequest;
@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) Favorite *favorite;
@property (strong, nonatomic) UIPopoverController *popover;
@end

@implementation WFArtMetadataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    width = screenWidth();
    height = screenHeight();
    
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    editMode = NO;
    [self setupDateFormatter];
    [self registerForKeyboardNotifications];
    self.photo = [self.photo MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    [self loadPhotoMetadata];
    
    // one time setup methods for photo scrollview
    [self.photoScrollView setBackgroundColor:[UIColor clearColor]];
    self.photoScrollView.delegate = self;
    self.photoScrollView.pagingEnabled = YES;
    [self.photoScrollView setCanCancelContentTouches:YES];
    [self drawHeader];
    
    if (IDIOM == IPAD){
        //[self drawHeader];
    } else {
        moreButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(showiPhoneOptions)];
        self.navigationItem.rightBarButtonItem = moreButton;
        saveBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveMetadata)];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        UIBarButtonItem *dismissBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismiss)];
        self.navigationItem.leftBarButtonItem = dismissBarButton;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (IDIOM == IPAD){
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    } else {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault]; // make the nav bar invisible
        [self.navigationController.navigationBar setBackgroundColor:[UIColor whiteColor]];
        [self.dismissButton setHidden:YES]; // don't need this on the iphone
        
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"]; // force portrait orientation
        
    }
    width = screenWidth();
    height = screenHeight();
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (IDIOM == IPAD){
        originalViewFrame = self.view.frame;
        originalNavFrame = self.navigationController.view.frame;
    }
}

- (void)setupDateFormatter {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
}

- (void)drawHeader {
    CGSize viewSize = self.view.frame.size;
    CGRect topImageContainerFrame = _topImageContainerView.frame;
    if (IDIOM == IPAD){
        [self setUpButtons];
        CGRect dismissFrame = self.dismissButton.frame;
        dismissFrame.origin.x = viewSize.width-dismissFrame.size.width;
        [self.dismissButton setFrame:dismissFrame];
    } else {
        topImageContainerFrame.size.height = width + (self.photo.art.photos.count > 1 ? 88.f : 44.f);
        [_topImageContainerView setFrame:topImageContainerFrame];
    }
    
    self.tableView.tableHeaderView = _topImageContainerView;
    currentPhotoIdx = [self.photo.art.photos indexOfObject:self.photo];
    [self setPhotoCount:currentPhotoIdx+1]; // setPhotoCredit called at the end of setPhotoCount... no worries
    [_nextPhotoButton addTarget:self action:@selector(nextPhoto) forControlEvents:UIControlEventTouchUpInside];
    [_lastPhotoButton addTarget:self action:@selector(lastPhoto) forControlEvents:UIControlEventTouchUpInside];
    [self.photoCountLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];

    [self setupPhotoScrollView];
}

- (void)showiPhoneOptions {
    UIActionSheet *iPhoneOptionsSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Options for \"%@\"",self.photo.art.title] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:self.currentUser && _favorite ? unfavoriteOption : favoriteOption, lightTableOption, tagOption, flagOption, nil];
    
    if (self.currentUser && [self.photo.user.identifier isEqualToNumber:self.currentUser.identifier]){
        [iPhoneOptionsSheet addButtonWithTitle:editOption];
        [iPhoneOptionsSheet addButtonWithTitle:deleteOption];
    } else if ([self.photo.art.communityEditable isEqualToNumber:@YES]){
        [iPhoneOptionsSheet addButtonWithTitle:communityEditOption];
    }
    iPhoneOptionsSheet.delegate = self;
    [iPhoneOptionsSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == flagActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Inappropriate"]){
            [self flag];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Copyright"]) {
            [self performSegueWithIdentifier:@"Flag" sender:kCopyright];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Incorrect metadata"]) {
            [self performSegueWithIdentifier:@"Flag" sender:nil];
        }
    } else if (actionSheet == eraActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"CE"]){
            [_eraButton setTitle:@"CE" forState:UIControlStateNormal];
            [_eraButton setSelected:YES];
            [self.photo.art.interval setSuffix:@"CE"];
            [_eraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"BCE"])  {
            [_eraButton setTitle:@"BCE" forState:UIControlStateNormal];
            [_eraButton setSelected:YES];
            [self.photo.art.interval setSuffix:@"BCE"];
            [_eraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Clear"])  {
            [_eraButton setTitle:@"CE" forState:UIControlStateNormal];
            [_eraButton setSelected:NO];
            [_eraButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
            [self.photo.art.interval setSuffix:nil];
        }
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
        }];
    } else if (actionSheet == beginEraActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"CE"]){
            [_beginEraButton setTitle:@"CE" forState:UIControlStateNormal];
            [_beginEraButton setSelected:YES];
            [_beginEraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.photo.art.interval setBeginSuffix:@"CE"];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"BCE"]) {
            [_beginEraButton setTitle:@"BCE" forState:UIControlStateNormal];
            [_beginEraButton setSelected:YES];
            [_beginEraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.photo.art.interval setBeginSuffix:@"BCE"];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Clear"]) {
            [_beginEraButton setTitle:@"CE" forState:UIControlStateNormal];
            [_beginEraButton setSelected:NO];
            [_beginEraButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
            [self.photo.art.interval setBeginSuffix:nil];
        }
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
        }];
    } else if (actionSheet == endEraActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"CE"]){
            [_endEraButton setTitle:@"CE" forState:UIControlStateNormal];
            [_endEraButton setSelected:YES];
            [_endEraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.photo.art.interval setEndSuffix:@"CE"];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"BCE"]) {
            [_endEraButton setTitle:@"BCE" forState:UIControlStateNormal];
            [_endEraButton setSelected:YES];
            [_endEraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.photo.art.interval setEndSuffix:@"BCE"];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Clear"])  {
            [_endEraButton setTitle:@"CE" forState:UIControlStateNormal];
            [_endEraButton setSelected:NO];
            [_endEraButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
            [self.photo.art.interval setEndSuffix:nil];
        }
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    } else {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:unfavoriteOption]){
            [self unfavorite];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:favoriteOption]){
            [self createFavorite];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:lightTableOption]){
            [self dropToLightTable];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:tagOption]){
            [self communityTag];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:flagOption]){
            [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .5f * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self presentFlagActionSheet];
            });
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:editOption] || [[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:communityEditOption]){
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .5f * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self edit];
            });
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:deleteOption]){
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .5f * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self confirmDeletion];
            });
        }
    }
}

- (void)setPhotoCount:(NSInteger)currentIdx{
    CGFloat landscapeWidth = IDIOM == IPAD ? 380.f : width;
    if (self.photo.art.photos.count <= 1){
        [_photoCountLabel setHidden:YES];
        [_nextPhotoButton setHidden:YES];
        [_lastPhotoButton setHidden:YES];
    } else {
        [self.photoCountLabel setText:[NSString stringWithFormat:@"%ld of %lu photos",(long)currentIdx, (unsigned long)self.photo.art.photos.count]];
    }
    if (self.photo.art.photos.count <= 1){
        
    }
    
    if (self.photoScrollView.contentOffset.x < landscapeWidth/2){
        [_lastPhotoButton setEnabled:NO];
        [_nextPhotoButton setEnabled:YES];
    } else if (self.photoScrollView.contentOffset.x >= ((self.photo.art.photos.count-1)*landscapeWidth)-landscapeWidth/2) {
        [_nextPhotoButton setEnabled:NO];
        [_lastPhotoButton setEnabled:YES];
    } else {
        [_lastPhotoButton setEnabled:YES];
        [_nextPhotoButton setEnabled:YES];
    }

    [self setPhotoCredit];
}

- (void)setupPhotoScrollView {
    // remove all the stuff from before!
    [self.photoScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSInteger idx = 0;
    CGFloat landscapeWidth, landscapeHeight, portraitWidth, portraitHeight;
    if (IDIOM == IPAD){
        landscapeWidth = IDIOM == IPAD ? 380.f : height;
        landscapeHeight = IDIOM == IPAD ? 260.f : height;
        portraitWidth = IDIOM == IPAD ? 260.f : height;
        portraitHeight = IDIOM == IPAD ? 380.f : height;
    } else {
        landscapeWidth = IDIOM == IPAD ? 380.f : width;
        landscapeHeight = IDIOM == IPAD ? 260.f : width;
        portraitWidth = IDIOM == IPAD ? 260.f : width;
        portraitHeight = IDIOM == IPAD ? 380.f : width;
    }
    
    if (IDIOM != IPAD){
        [self.photoScrollView setFrame:CGRectMake(0, 44, landscapeWidth, landscapeWidth)];
    }
    
    for (Photo *photo in self.photo.art.photos){
        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [imageButton setShowsTouchWhenHighlighted:NO];
        [imageButton setAdjustsImageWhenHighlighted:NO];
        imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.photoScrollView addSubview:imageButton];
        if (photo.isLandscape){
            if (IDIOM == IPAD){
                [imageButton setFrame:CGRectMake(0+(idx*landscapeWidth), 60, landscapeWidth, landscapeHeight)];
            } else {
                [imageButton setFrame:CGRectMake(0+(idx*landscapeWidth), 0, landscapeWidth, landscapeHeight)];
            }
        } else {
            if (IDIOM == IPAD){
                [imageButton setFrame:CGRectMake(60+(idx*landscapeWidth), 0, portraitWidth, portraitHeight)];
            } else {
                [imageButton setFrame:CGRectMake((idx*landscapeWidth), 0, portraitWidth, portraitHeight)];
            }
        }
        
        [_progressIndicator setHidden:YES];
        __weak typeof(UIButton*) weakImageButton = imageButton;
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:photo.slideImageUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
        [imageButton setImageForState:UIControlStateNormal withURLRequest:imageRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
            [weakImageButton setImage:image forState:UIControlStateNormal];
        } failure:^(NSError * error) {
            [UIView animateWithDuration:.23 animations:^{
                [weakImageButton setAlpha:1.0];
            } completion:^(BOOL finished) {
                [_progressIndicator removeFromSuperview];
                weakImageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
                weakImageButton.imageView.layer.shouldRasterize = YES;
            }];
        }];
        [imageButton addTarget:self action:@selector(showFullScreen) forControlEvents:UIControlEventTouchUpInside];
        idx ++;
    }
    
    [self.photoScrollView setContentSize:CGSizeMake(self.photo.art.photos.count * landscapeWidth, landscapeWidth)]; //  use 380 as a max
    [self.photoScrollView setContentOffset:CGPointMake(landscapeWidth * currentPhotoIdx, 0) animated:YES];
    self.photoScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.photoScrollView.layer.shouldRasterize = YES;
}

- (void)setPhotoCredit {
    NSString *stringContent;
    if (self.photo.partners.count){
        stringContent = self.photo.partnersToSentence;
    } else if (self.photo.user && self.photo.user.fullName.length){
        stringContent = self.photo.user.fullName;
    }
    
    if (stringContent.length){
        NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        [_postedByButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
        NSMutableAttributedString *postedByString = [[NSMutableAttributedString alloc] initWithString:@"POSTED BY:" attributes:@{NSFontAttributeName : [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor blackColor],NSParagraphStyleAttributeName:paragraphStyle}];
       [postedByString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@",stringContent] attributes:@{NSFontAttributeName : [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : kElectricBlue, NSParagraphStyleAttributeName:paragraphStyle}]];
        [_postedByButton setAttributedTitle:postedByString forState:UIControlStateNormal];
        [_postedByButton addTarget:self action:@selector(showProfile) forControlEvents:UIControlEventTouchUpInside];
        [_postedByButton.titleLabel setNumberOfLines:0];
        [_postedByButton setHidden:NO];
        if (IDIOM != IPAD){
            self.navigationItem.titleView = _postedByButton;
        }
    } else {
        [_postedByButton setHidden:YES];
    }
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:6 inSection:0],[NSIndexPath indexPathForRow:7 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)nextPhoto {
    CGFloat landscapeWidth = IDIOM == IPAD ? 380.f : width;
    [self.photoScrollView setContentOffset:CGPointMake(self.photoScrollView.contentOffset.x + landscapeWidth, 0) animated:YES];
    currentPhotoIdx ++;
}

- (void)lastPhoto {
    CGFloat landscapeWidth = IDIOM == IPAD ? 380.f : width;
    [self.photoScrollView setContentOffset:CGPointMake(self.photoScrollView.contentOffset.x - landscapeWidth, 0) animated:YES];
    currentPhotoIdx --;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.photoScrollView){
        CGFloat contentSizeWidth = scrollView.frame.size.width;
        CGFloat offsetX = scrollView.contentOffset.x;
        float fractionalPage = offsetX / contentSizeWidth;
        NSInteger page = lround(fractionalPage);
        if (currentPhotoIdx != page) {
            currentPhotoIdx = page;
            Art *art = self.photo.art;
            if (currentPhotoIdx < art.photos.count){
                self.photo = art.photos[currentPhotoIdx];
            }
            [self setPhotoCount:currentPhotoIdx + 1]; // make sure to offset by 1
        }
        CGFloat landscapeWidth = IDIOM == IPAD ? 380.f : width;
        if (offsetX > self.photoScrollView.contentSize.width - landscapeWidth/2){
            [_nextPhotoButton setEnabled:NO];
        }
    }
}

- (void)setUpButtons {
    [_flagButton addTarget:self action:@selector(presentFlagActionSheet) forControlEvents:UIControlEventTouchUpInside];
    [_flagButton setImage:[UIImage imageNamed:@"flag"] forState:UIControlStateNormal];
    [_flagButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
    [_flagButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    
    [_tagButton addTarget:self action:@selector(communityTag) forControlEvents:UIControlEventTouchUpInside];
    [_tagButton setImage:[UIImage imageNamed:@"tag"] forState:UIControlStateNormal];
    [_tagButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
    [_tagButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    
    [_dropToTableButton addTarget:self action:@selector(dropToLightTable) forControlEvents:UIControlEventTouchUpInside];
    [_dropToTableButton setImage:[UIImage imageNamed:@"dropToLightTable"] forState:UIControlStateNormal];
    [_dropToTableButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
    [_dropToTableButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    
    if (self.currentUser && [self.photo.user.identifier isEqualToNumber:self.currentUser.identifier]){
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
        [saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [saveButton addTarget:self action:@selector(saveMetadata) forControlEvents:UIControlEventTouchUpInside];
        [saveButton setTitle:@"SAVE" forState:UIControlStateNormal];
        saveButton.layer.cornerRadius = 7.f;
        [saveButton setBackgroundColor:kSaffronColor];
        
    } else {
        [_editButton removeFromSuperview];
        [_deleteButton removeFromSuperview];
    }
    
    [_favoriteButton setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
    [_favoriteButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    self.favorite = [self.currentUser getFavoritePhoto:self.photo];
    if (self.currentUser && _favorite){
        [_favoriteButton setTitle:@"   Favorited!" forState:UIControlStateNormal];
        [_favoriteButton addTarget:self action:@selector(unfavorite) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [_favoriteButton addTarget:self action:@selector(createFavorite) forControlEvents:UIControlEventTouchUpInside];
        [_favoriteButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
    }
}

- (void)dropToLightTable {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        if (self.currentUser.customerPlan.length){
            WFLightTablesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"LightTables"];
            vc.lightTableDelegate = self;
            [vc setPhoto:self.photo];
            [vc setLightTables:self.currentUser.lightTables.array.mutableCopy];
            
            if (IDIOM == IPAD){
                if (self.popover){
                    [self.popover dismissPopoverAnimated:YES];
                }
                CGFloat vcHeight = self.currentUser.lightTables.count*54.f > 260.f ? 260 : (self.currentUser.lightTables.count)*54.f;
                vc.preferredContentSize = CGSizeMake(420, vcHeight+34.f); // add the header height
                self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
                self.popover.delegate = self;
                [self.popover presentPopoverFromRect:CGRectMake(_dropToTableButton.center.x,(_dropToTableButton.center.y+_dropToTableButton.frame.size.height/2),1,1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES]; // added 23 points to the popover rect to make the arrow look nicerp
            } else {
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self resetTransitionBooleans];
                lightTables = YES;
                nav.transitioningDelegate = self;
                nav.modalPresentationStyle = UIModalPresentationCustom;
                [self presentViewController:nav animated:YES completion:NULL];
            }
            
        } else {
            [WFAlert show:@"Dropping images onto a light table requires a billing plan.\n\nPlease either set up an individual billing plan or add yourself as a member to an institution that's been registered with Wölff." withTime:4.7f];
        }
    } else {
        [self showLogin];
    }
}

- (void)newLightTable {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        if (self.currentUser.customerPlan.length){
            WFLightTableDetailsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"LightTableDetails"];
            [vc setPhotos:[[NSMutableOrderedSet alloc] initWithObject:self.photo]];
            vc.lightTableDelegate = self;
            [self resetTransitionBooleans];
            newLightTableTransition = YES;
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                if (IDIOM == IPAD){
                    vc.modalPresentationStyle = UIModalPresentationCustom;
                    vc.transitioningDelegate = self;
                    [self presentViewController:vc animated:YES completion:NULL];
                } else {
                    WFNoRotateNavController *nav = [[WFNoRotateNavController alloc] initWithRootViewController:vc];
                    nav.modalPresentationStyle = UIModalPresentationCustom;
                    nav.transitioningDelegate = self;
                    [self presentViewController:nav animated:YES completion:NULL];
                }
            }];
        } else {
            [WFAlert show:@"Joining or creating light tables requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
        }
    } else {
        [self showLogin];
    }
}

- (void)lightTableSelected:(LightTable *)l {
    LightTable *lightTable = [l MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    [lightTable addPhoto:self.photo];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    //ensure we're playing with a real light table first
    if (![lightTable.identifier isEqualToNumber:@0]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:self.photo.identifier forKey:@"photo_id"];
        [manager POST:[NSString stringWithFormat:@"light_tables/%@/add",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success dropping metadata photo to light table: %@",responseObject);
            if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToNumber:@1]){
                if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(droppedPhoto:toLightTable:)]){
                    [self.metadataDelegate droppedPhoto:self.photo toLightTable:lightTable];
                }
            } else {
                [WFAlert show:@"Something went wrong while trying to drop this art to your light table. Please try again soon" withTime:3.3f];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to drop metadata photo to light table: %@",error.description);
        }];
    }
}

- (void)undropPhotoFromLightTable:(LightTable *)l {
    //refetch the light table
    LightTable *lightTable = [l MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    [lightTable removePhoto:self.photo];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self setUpButtons];
    
    //ensure we're playing with a real light table first
    if (![lightTable.identifier isEqualToNumber:@0]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:self.photo.identifier forKey:@"photo_id"];
        [manager DELETE:[NSString stringWithFormat:@"light_tables/%@/remove",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success UNdropping metadata photo to light table: %@",responseObject);
            if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToNumber:@1]){
                if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(removedPhoto:fromLightTable:)]){
                    [self.metadataDelegate removedPhoto:self.photo fromLightTable:lightTable];
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
    self.photo = self.photo.art.photos[currentPhotoIdx];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    if (editMode){
        CGRect newViewFrame = originalViewFrame; // only relevant for iPad
        if (IDIOM == IPAD){
            newViewFrame.origin.y = 0;
            newViewFrame.origin.x -= 100;
            newViewFrame.size.width += 200;
            CGRect navFrame = self.navigationController.view.frame;
            navFrame.size.width = newViewFrame.size.width;
            navFrame.origin.x = (width-navFrame.size.width)/2;
            [self.navigationController.view setFrame:navFrame];
        } else {
            self.navigationItem.rightBarButtonItem = saveBarButton;
        }
        self.tableView.tableFooterView = saveContainerView;
        [UIView animateWithDuration:.77 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [_nextPhotoButton setAlpha:0.0];
            [_lastPhotoButton setAlpha:0.0];
            if (IDIOM == IPAD) {
                [self.view setFrame:newViewFrame];
                [saveButton setFrame:CGRectMake(20, 13, newViewFrame.size.width-40, 44)];
            }
        } completion:^(BOOL finished) {
            [_nextPhotoButton setHidden:YES];
            [_lastPhotoButton setHidden:YES];
            [self.photoScrollView setUserInteractionEnabled:NO];
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
        if (IDIOM != IPAD){
            self.navigationItem.rightBarButtonItem = moreButton;
        }
        [UIView animateWithDuration:.77 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (IDIOM == IPAD){
                [self.view setFrame:originalViewFrame];
                [self.navigationController.view setFrame:originalNavFrame];
            }
            self.tableView.tableFooterView = nil;
            [_nextPhotoButton setHidden:NO];
            [_lastPhotoButton setHidden:NO];
            [self.photoScrollView setUserInteractionEnabled:YES];
            [_nextPhotoButton setAlpha:1.0];
            [_lastPhotoButton setAlpha:1.0];
            [_tableView setContentOffset:CGPointZero animated:NO];
        } completion:^(BOOL finished) {
            [self.tableView setBackgroundColor:[UIColor clearColor]];
        }];
    }
}

- (void)loginSuccessful {
    [self setUpButtons];
    [ProgressHUD dismiss];
}

- (void)logout {
    [self setUpButtons];
    [ProgressHUD dismiss];
}

- (void)showProfile {
    UINavigationController *nav;
    if (self.photo.partners.count){
        WFPartnerProfileViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"PartnerProfile"];
        [vc setPartner:self.photo.partners.firstObject];
        nav = [[UINavigationController alloc] initWithRootViewController:vc];
    } else {
        WFProfileViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
        [vc setUser:self.photo.user];
        nav = [[UINavigationController alloc] initWithRootViewController:vc];
    }
    
    [self resetTransitionBooleans];
    profile = YES;
    
    if (IDIOM == IPAD){
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
    }
    
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)loadPhotoMetadata {
    if (self.mainRequest) return;
    
    self.mainRequest = [manager GET:[NSString stringWithFormat:@"photos/%@",self.photo.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success fetching metadata: %@",responseObject);
        [self.photo populateFromDictionary:[responseObject objectForKey:@"photo"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.mainRequest && !self.mainRequest.isCancelled){
                [self.tableView reloadData];
            }
            self.mainRequest = nil;
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([operation.responseString isEqualToString:kNoPhoto]){
            [self.photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            [WFAlert show:@"Sorry, but something went wrong while trying to fetch this record.\n\nThe creator may have expunged it from our database." withTime:3.7f];
            if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(photoDeleted:)]){
                [self.metadataDelegate photoDeleted:self.photo];
            }
            [self dismiss];
        }
    }];
}

- (void)saveMetadata {
    if (!titleTextView.text){
        [WFAlert show:@"Please ensure your art has a title before continuing." withTime:2.7f];
        return;
    }
    [ProgressHUD show:@"Saving..."];
    [self.view endEditing:YES];
    
    //photo parameters
    NSMutableDictionary *photoParameters = [NSMutableDictionary dictionary];
    [photoParameters setObject:@(privateSwitch.isOn) forKey:@"priv"];
    [photoParameters setObject:creditTextView.text forKey:@"credit"];
    NSMutableArray *iconIds = [NSMutableArray arrayWithCapacity:self.photo.icons.count];
    for (Icon *icon in self.photo.icons){
        [iconIds addObject:icon.identifier];
    }
    [photoParameters setObject:iconIds forKey:@"icon_ids"];
    
    // art parameters
    NSMutableDictionary *artParameters = [NSMutableDictionary dictionary];
    [artParameters setObject:titleTextView.text forKey:@"title"];
    [artParameters setObject:notesTextView.text forKey:@"notes"];
    NSMutableArray *artistIds = [NSMutableArray arrayWithCapacity:self.photo.art.artists.count];
    for (Artist *artist in self.photo.art.artists){
        [artistIds addObject:artist.identifier];
    }
    [artParameters setObject:artistIds forKey:@"artist_ids"];
    
    NSMutableArray *locationIds = [NSMutableArray arrayWithCapacity:self.photo.art.locations.count];
    for (Location *location in self.photo.art.locations){
        [locationIds addObject:location.identifier];
    }
    [artParameters setObject:locationIds forKey:@"location_ids"];
    
    NSMutableArray *tagIds = [NSMutableArray arrayWithCapacity:self.photo.art.tags.count];
    for (Tag *tag in self.photo.art.tags){
        [tagIds addObject:tag.identifier];
    }
    [artParameters setObject:tagIds forKey:@"tag_ids"];
    
    NSMutableArray *materialIds = [NSMutableArray arrayWithCapacity:self.photo.art.materials.count];
    for (Material *material in self.photo.art.materials){
        [materialIds addObject:material.identifier];
    }
    [artParameters setObject:materialIds forKey:@"material_ids"];
    
    if (self.photo.art.interval){
        [artParameters setObject:self.photo.art.interval.year forKey:@"interval[year]"];
        if (![self.photo.art.interval.beginRange isEqualToNumber:@0]){
            [artParameters setObject:self.photo.art.interval.beginRange forKey:@"interval[begin_range]"];
        }
        if (![self.photo.art.interval.endRange isEqualToNumber:@0]){
            [artParameters setObject:self.photo.art.interval.endRange forKey:@"interval[end_range]"];
        }
        if (![self.photo.art.interval.year isEqualToNumber:@0]){
            [artParameters setObject:self.photo.art.interval.year forKey:@"interval[year]"];
        }
        if (self.photo.art.interval.circa){
            [artParameters setObject:self.photo.art.interval.circa forKey:@"interval[circa]"];
        }
        if (_eraButton.selected && self.photo.art.interval.suffix.length){
            [artParameters setObject:self.photo.art.interval.suffix forKey:@"interval[suffix]"];
        } else {
            [artParameters setObject:@"" forKey:@"interval[suffix]"];
        }
        if (_beginEraButton.selected && self.photo.art.interval.beginSuffix.length){
            [artParameters setObject:self.photo.art.interval.beginSuffix forKey:@"interval[begin_suffix]"];
        } else {
            [artParameters setObject:@"" forKey:@"interval[begin_suffix]"];
        }
        if (_endEraButton.selected && self.photo.art.interval.endSuffix.length){
            [artParameters setObject:self.photo.art.interval.endSuffix forKey:@"interval[end_suffix]"];
        } else {
            [artParameters setObject:@"" forKey:@"interval[end_suffix]"];
        }
    }
    
    [manager PATCH:[NSString stringWithFormat:@"photos/%@",self.photo.identifier] parameters:@{@"photo":photoParameters,@"art":artParameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success saving metadata: %@",responseObject);
        [self.photo populateFromDictionary:[responseObject objectForKey:@"photo"]];
        
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (editMode){
        return 10;
    } else {
        return 9;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFArtMetadataCell *cell = (WFArtMetadataCell *)[tableView dequeueReusableCellWithIdentifier:@"ArtMetadataCell"];
    [cell setDefaultStyle:editMode];
    cell.textView.delegate = self;
    
    switch (indexPath.row) {
        case 0:
            [cell.label setText:@"TITLE"];
            [cell.textView setText:self.photo.art.title];
            titleTextView = cell.textView;
            break;
        case 1:
        {
            [cell.label setText:@"ARTIST(S)"];
            artistTextView = cell.textView;
            if (self.photo.art.artists.count){
                NSString *artists = [self.photo.art artistsToSentence];
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
        {
            if (editMode){
                WFDateMetadataCell *dateCell = (WFDateMetadataCell *)[tableView dequeueReusableCellWithIdentifier:@"DateMetadataCell"];
                [dateCell setBackgroundColor:[UIColor whiteColor]];
                [dateCell configureArt:self.photo.art forEditMode:YES];
                [dateCell.circaSwitch addTarget:self action:@selector(circaSwitchSwitched:) forControlEvents:UIControlEventValueChanged];
                
                beginYearTextField = dateCell.beginYearTextField;
                endYearTextField = dateCell.endYearTextField;
                dateTextField = dateCell.singleYearTextField;
                beginYearTextField.delegate = self;
                endYearTextField.delegate = self;
                dateTextField.delegate = self;
                
                _eraButton = dateCell.eraButton;
                [dateCell.eraButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
                
                _beginEraButton = dateCell.beginEraButton;
                [dateCell.beginEraButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
                
                _endEraButton = dateCell.endEraButton;
                [dateCell.endEraButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
                
                return dateCell;
            } else {
                [cell.label setText:@"DATE"];
                dateTextView = cell.textView;
                NSMutableAttributedString *dateString;
                if (self.photo.art.interval.single){
                    dateString = [[NSMutableAttributedString alloc] initWithString:[dateFormatter stringFromDate:self.photo.art.interval.single] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]}];
                } else if (self.photo.art.interval.beginRange && ![self.photo.art.interval.beginRange isEqualToNumber:@0] && self.photo.art.interval.endRange && ![self.photo.art.interval.endRange isEqualToNumber:@0]) {
                    NSString *beginSuffix = self.photo.art.interval.beginSuffix.length ? self.photo.art.interval.beginSuffix : @"CE";
                    NSString *endSuffix = self.photo.art.interval.endSuffix.length ? self.photo.art.interval.endSuffix : @"CE";
                    dateString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@ - %@ %@",self.photo.art.interval.beginRange, beginSuffix, self.photo.art.interval.endRange, endSuffix] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]}];
                    
                } else if (self.photo.art.interval.year && ![self.photo.art.interval.year isEqualToNumber:@0]){
                    NSString *suffix = self.photo.art.interval.suffix.length ? self.photo.art.interval.suffix : @"CE";
                    dateString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@",self.photo.art.interval.year, suffix] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]}];
    
                } else {
                    dateString = [[NSMutableAttributedString alloc] initWithString:@"No date listed" attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0], NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
                }
                
                if ([self.photo.art.interval.circa isEqualToNumber:@YES]){
                    [dateString appendAttributedString:[[NSAttributedString alloc] initWithString:@"  circa" attributes:@{NSForegroundColorAttributeName:[UIColor blackColor],NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLightItalic] size:0]}]];
                }
                [cell.textView setAttributedText:dateString];
                [cell.textView setKeyboardType:UIKeyboardTypeNumberPad];
            }
        }
            break;
        case 3:
        {
            [cell.label setText:@"LOCATION"];
            locationTextView = cell.textView;
            if (self.photo.art.locations.count){
                NSString *locations = [self.photo.art locationsToSentence];
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
            [cell.label setText:@"TAGS"];
            tagsTextView = cell.textView;
            if (self.photo.art.tags.count){
                NSString *tags = [self.photo.art tagsToSentence];
                [cell.textView setText:tags];
            } else {
                [cell.textView setText:@"No tags listed"];
                [cell.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textView setTextColor:[UIColor lightGrayColor]];
            }
            [cell.textView setUserInteractionEnabled:NO];
        }
            break;
        case 5:
        {
            [cell.label setText:@"MATERIAL(S)"];
            materialTextView = cell.textView;
            if (self.photo.art.materials.count){
                NSString *materials = [self.photo.art materialsToSentence];
                [cell.textView setText:materials];
            } else {
                [cell.textView setText:@"No materials listed"];
                [cell.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textView setTextColor:[UIColor lightGrayColor]];
            }
            [cell.textView setUserInteractionEnabled:NO];
        }
            break;
        case 6:
        {
            [cell.label setText:@"ICONOGRAPHY"];
            iconographyTextView = cell.textView;
            if (self.photo.art.icons.count){
                NSString *icons = [self.photo iconsToSentence];
                [cell.textView setText:icons];
            } else {
                [cell.textView setText:@"N/A"];
                [cell.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textView setTextColor:[UIColor lightGrayColor]];
            }
            [cell.textView setUserInteractionEnabled:NO];
        }
            break;
        case 7:
            [cell.label setText:@"CREDIT / RIGHTS"];
            [cell.textView setText:(self.photo.credit.length ? self.photo.credit : self.photo.user.fullName)];
            creditTextView = cell.textView;
            break;
        case 8:
            [cell.label setText:@"NOTES"];
            notesTextView = cell.textView;
            [cell.textView setText:self.photo.notes];
            break;
        case 9:
            [cell.label setText:@"PRIVATE"];
            [cell.privateSwitch setHidden:NO];
            privateSwitch = cell.privateSwitch;
            [privateSwitch setOn:self.photo.privatePhoto.boolValue];
            [privateSwitch addTarget:self action:@selector(privateSwitchSwitched:) forControlEvents:UIControlEventValueChanged];
            [cell.textView setHidden:YES];
            return cell; // no need to go any further
            break;
            
        default:
            break;
    }
    
    // fancy text fade in
    [UIView animateWithDuration:kFastAnimationDuration animations:^{
        if (cell.textView.text.length) {
            [cell.textView setAlpha:1.0];
        }
    }];
    
    //size the text view appropriately
    CGSize textViewSize = [cell.textView sizeThatFits:CGSizeMake(cell.textView.frame.size.width, CGFLOAT_MAX)];
    CGRect textViewRect = cell.textView.frame;
    textViewRect.size.height = textViewSize.height;
    CGFloat estimatedRowHeight = textViewSize.height < 60.f ? 60.f : textViewSize.height; // make sure the text view height is at least 60
    textViewRect.origin.y = estimatedRowHeight/2 - textViewSize.height/2;
    [cell.textView setFrame:textViewRect];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat rowHeight;
    
    if (indexPath.row == 0){
        CGSize size = [titleTextView sizeThatFits:CGSizeMake(titleTextView.frame.size.width, CGFLOAT_MAX)];
        rowHeight = size.height;
    } else if (indexPath.row == 1){
        CGSize size = [artistTextView sizeThatFits:CGSizeMake(artistTextView.frame.size.width, CGFLOAT_MAX)];
        rowHeight = size.height;
    } else if (indexPath.row == 2){
        
        if (editMode){
            return 110.f;
        } else {
            CGSize size = [dateTextView sizeThatFits:CGSizeMake(dateTextView.frame.size.width, CGFLOAT_MAX)];
            rowHeight = size.height;
        }
    } else if (indexPath.row == 3){
        CGSize size = [tagsTextView sizeThatFits:CGSizeMake(tagsTextView.frame.size.width, CGFLOAT_MAX)];
        rowHeight = size.height;
    } else if (indexPath.row == 4){
        CGSize size = [materialTextView sizeThatFits:CGSizeMake(materialTextView.frame.size.width, CGFLOAT_MAX)];
        rowHeight = size.height;
    } else if (indexPath.row == 5){
        CGSize size = [iconographyTextView sizeThatFits:CGSizeMake(iconographyTextView.frame.size.width, CGFLOAT_MAX)];
        rowHeight = size.height;
    } else if (indexPath.row == 6){
        CGSize size = [locationTextView sizeThatFits:CGSizeMake(locationTextView.frame.size.width, CGFLOAT_MAX)];
        rowHeight = size.height;
    } else if (indexPath.row == 7){
        CGSize size = [creditTextView sizeThatFits:CGSizeMake(creditTextView.frame.size.width, CGFLOAT_MAX)];
        rowHeight = size.height;
    } else if (indexPath.row == 8) {
        CGSize size = [notesTextView sizeThatFits:CGSizeMake(notesTextView.frame.size.width, CGFLOAT_MAX)];
        rowHeight = size.height;
    }
    
    return rowHeight < 60.f ? 60.f : rowHeight; // make sure we return at least 60 for the row height
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editMode){
        if (indexPath.row == 1){
            [self showArtists];
        } else if (indexPath.row == 3){
            [self showLocations];
        } else if (indexPath.row == 4){
            [self showTags];
        } else if (indexPath.row == 5){
            [self showMaterials];
        } else if (indexPath.row == 6){
            [self showIcons];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showArtists {
    [self resetTransitionBooleans];
    metadataModal = YES;
    WFArtistsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Artists"];
    [vc setSelectedArtists:self.photo.art.artists.mutableCopy];
    vc.artistDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if (IDIOM == IPAD){
        nav.modalPresentationStyle = UIModalPresentationCustom;
        nav.transitioningDelegate = self;
    }
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)artistsSelected:(NSOrderedSet *)selectedArtists {
    self.photo.art.artists = selectedArtists;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)showLocations {
    
    WFLocationsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Locations"];
    [vc setSelectedLocations:self.photo.art.locations.mutableCopy];
    vc.locationDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if (IDIOM == IPAD){
        [self resetTransitionBooleans];
        metadataModal = YES;
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
    }
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)locationsSelected:(NSOrderedSet *)selectedLocations {
    self.photo.art.locations = selectedLocations;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)communityTag {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        WFTagsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Tags"];
        [vc setCommunityTagMode:YES];
        [vc setArt:self.photo.art];
        [vc setSelectedTags:[NSMutableOrderedSet orderedSet]];
        vc.tagDelegate = self;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        if (IDIOM == IPAD){
            nav.transitioningDelegate = self;
            nav.modalPresentationStyle = UIModalPresentationCustom;
            [self resetTransitionBooleans];
            metadataModal = YES;
        }
        [self presentViewController:nav animated:YES completion:NULL];
    } else {
        [self showLogin];
    }
}

- (void)showTags {
    WFTagsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Tags"];
    [vc setCommunityTagMode:NO];
    [vc setArt:self.photo.art];
    [vc setSelectedTags:self.photo.art.tags.mutableCopy];
    vc.tagDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if (IDIOM == IPAD){
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self resetTransitionBooleans];
        metadataModal = YES;
    }
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)tagsSelected:(NSOrderedSet *)selectedTags {
    self.photo.art.tags = selectedTags;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:4 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)showMaterials {
    WFMaterialsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Materials"];
    [vc setSelectedMaterials:self.photo.art.materials.mutableCopy];
    vc.materialDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if (IDIOM == IPAD){
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self resetTransitionBooleans];
        metadataModal = YES;
    }
    
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)materialsSelected:(NSOrderedSet *)selectedMaterials {
    self.photo.art.materials = selectedMaterials;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:5 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }];
    
}

- (void)showIcons {

    WFIconsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Icons"];
    [vc setSelectedIcons:self.photo.icons.mutableCopy];
    vc.iconsDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if (IDIOM == IPAD){
        [self resetTransitionBooleans];
        metadataModal = YES;
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
    }
    
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)iconsSelected:(NSOrderedSet *)selectedIcons {
    self.photo.icons = selectedIcons;
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:6 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)createFavorite {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        if (self.currentUser.customerPlan.length){
            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
            [manager POST:[NSString stringWithFormat:@"photos/%@/favorite",self.photo.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"posting favorite: %@",responseObject);
                _favorite = [Favorite MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [_favorite populateFromDictionary:[responseObject objectForKey:@"favorite"]];
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    [_favoriteButton setTitle:@"   Favorited!" forState:UIControlStateNormal];
                    [_favoriteButton removeTarget:nil
                                           action:NULL
                                 forControlEvents:UIControlEventAllEvents];
                    [_favoriteButton addTarget:self action:@selector(unfavorite) forControlEvents:UIControlEventTouchUpInside];
                    if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(favoritedPhoto:)]){
                        [self.metadataDelegate favoritedPhoto:self.photo];
                    }
                }];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to favorite %@: %@",self.photo.art.title,error.description);
            }];
        } else {
            [WFAlert show:@"\"Adding to favorites\" requires a billing plan.\n\nPlease either set up an individual billing plan or add yourself as a member to an institution that's been registered with Wölff." withTime:4.7f];
        }
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
            [_favoriteButton addTarget:self action:@selector(createFavorite) forControlEvents:UIControlEventTouchUpInside];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to unfavorite %@: %@",self.photo.art.title,error.description);
        }];
    } else {
        [self showLogin];
    }
}

- (void)resetTransitionBooleans {
    login = NO;
    metadataModal = NO;
    profile = NO;
    lightTables = NO;
}

- (void)showLogin {
    [self resetTransitionBooleans];
    login = YES;
    WFLoginViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
    delegate.loginDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    vc.transitioningDelegate = self;
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

- (void)showFullScreen {
    WFSlideshowViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Slideshow"];
    [vc setPhotos:@[self.photo]];
    
    if (IDIOM == IPAD){
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self resetTransitionBooleans];
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    } else {
        //WFNoRotateNavController *nav = [[WFNoRotateNavController alloc] initWithRootViewController:vc];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
//        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
//        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .5f * NSEC_PER_SEC);
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self presentViewController:nav animated:YES completion:^{
                
            }];
//        });
    }
}

- (void)presentFlagActionSheet {
    if (!flagActionSheet){
        flagActionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Why do you want to flag \"%@\"?",self.photo.art.title] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Inappropriate", @"Copyright", @"Incorrect metadata", nil];
        flagActionSheet.tintColor = kElectricBlue;
    }
    [flagActionSheet showInView:self.view];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"Flag"]){
        WFFlagViewController *vc = [segue destinationViewController];
        if (self.photo.art)[vc setArt:self.photo.art];
        if (self.photo)[vc setPhoto:self.photo];
        [vc setCurrentUser:self.currentUser];
        [vc setCopyright:[sender isEqualToString:kCopyright] ? YES : NO];
    }
}

// Don't allow rotation on metadata view for now
//- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
//    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
//        width = size.width;
//        height = size.height;
//        
//        if (IDIOM != IPAD){
//            CGRect dismissFrame = self.dismissButton.frame;
//            dismissFrame.origin.x = size.width-dismissFrame.size.width;
//            [self.dismissButton setFrame:dismissFrame];
//            [self drawHeader];
//        }
//        
//    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
//        
//    }];
//}

- (void)flag {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:self.photo.identifier forKey:@"photo_id"];
    [parameters setObject:self.photo.art.identifier forKey:@"art_id"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    [parameters setObject:@1 forKey:@"code"];
    [manager POST:[NSString stringWithFormat:@"flags"] parameters:@{@"flag":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a flag for %@, %@",self.photo.identifier, responseObject);
        [WFAlert show:@"Flagged" withTime:2.3f];
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
        if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(artFlagged:)]){
            [self.metadataDelegate artFlagged:self.photo.art];
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
        [manager DELETE:[NSString stringWithFormat:@"photos/%@",self.photo.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success deleting photo: %@",responseObject);
            [ProgressHUD dismiss];
            if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(photoDeleted:)]){
                [self.metadataDelegate photoDeleted:self.photo];
            }
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .5f * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [ProgressHUD dismiss];
                    [WFAlert show:@"Image expunged" withTime:2.7f];
                });
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
    keyboardUp = YES;
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
    keyboardUp = NO;
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
    self.photo.art.interval.circa = [NSNumber numberWithBool:circaSwitch.isOn];
}

- (void)privateSwitchSwitched:(UISwitch*)leSwitch {
    self.photo.privatePhoto = [NSNumber numberWithBool:leSwitch.isOn];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    Interval *interval = self.photo.art.interval;
    
    if (textField == beginYearTextField){
        if (beginYearTextField.text.length){
            NSNumber *yearNumber = [f numberFromString:beginYearTextField.text];
            if (yearNumber){
                interval.beginRange = yearNumber;
            }
        } else {
            interval.beginRange = @0;
        }
    } else if (textField == endYearTextField){
        if (endYearTextField.text.length){
            NSNumber *yearNumber = [f numberFromString:endYearTextField.text];
            if (yearNumber){
                interval.endRange = yearNumber;
            }
        } else {
            interval.endRange = @0;
        }
    } else if (textField == dateTextField){
        if (dateTextField.text.length){
            NSNumber *yearNumber = [f numberFromString:dateTextField.text];
            if (yearNumber){
                interval.year = yearNumber;
            }
        } else {
            interval.year = @0;
        }
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (textView == titleTextView){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    } else if (textView == notesTextView){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:9 inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
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
    } else if (metadataModal){
        WFMetadataModalAnimator *animator = [WFMetadataModalAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (lightTables){
        WFTransparentBGModalAnimator *animator = [WFTransparentBGModalAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (newLightTableTransition){
        WFNewLightTableAnimator *animator = [WFNewLightTableAnimator new];
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
        WFProfileAnimator *animator = [WFProfileAnimator new];
        return animator;
    } else if (metadataModal){
        WFMetadataModalAnimator *animator = [WFMetadataModalAnimator new];
        return animator;
    } else if (lightTables){
        WFTransparentBGModalAnimator *animator = [WFTransparentBGModalAnimator new];
        return animator;
    } else if (newLightTableTransition){
        WFNewLightTableAnimator *animator = [WFNewLightTableAnimator new];
        return animator;
    } else {
        WFLoginAnimator *animator = [WFLoginAnimator new];
        return animator;
    }
}

- (void)confirmDismissWithoutSave {
    [[[UIAlertView alloc] initWithTitle:nil message:@"Do you want to save your change?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Save", nil] show];
}

- (void)dismiss {
    if ([self.navigationController.viewControllers.lastObject isKindOfClass:[WFFlagViewController class]]){
        WFFlagViewController *flagVC = self.navigationController.viewControllers.lastObject;
        if (flagVC.keyboardVisible){
            [flagVC.view endEditing:YES];
        }
    } else if (editMode){
        if (keyboardUp && IDIOM == IPAD){
            [self.view endEditing:YES];
        } else {
            [self.view endEditing:YES];
            [self edit];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.mainRequest cancel];
    self.mainRequest = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Dispose of any resources that can be recreated.
}

@end
