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

@interface WFArtMetadataViewController () <UITextViewDelegate, UIPopoverControllerDelegate, UIAlertViewDelegate, UIViewControllerTransitioningDelegate, WFLightTablesDelegate, WFLightTableDelegate, WFLoginDelegate, WFSelectArtistsDelegate, WFSelectLocationsDelegate, WFSelectIconsDelegate, WFSelectMaterialsDelegate, WFSelectTagsDelegate, UIActionSheetDelegate, UITextFieldDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    BOOL iOS8;
    NSDateFormatter *dateFormatter;
    BOOL editMode;
    BOOL keyboardUp;
    BOOL login;
    BOOL profile;
    BOOL newLightTableTransition;
    BOOL metadataModal;
    BOOL lightTables;
    BOOL landscape;
    CGFloat keyboardHeight;
    UITextView *titleTextView;
    UITextView *notesTextView;
    UITextView *creditTextView;
    UISwitch *privateSwitch;
    CGRect originalViewFrame;
    CGRect originalNavFrame;
    UIView *saveContainerView;
    UIButton *saveButton;
    UIImageView *navBarShadowView;
    CGFloat rowHeight;
    CGFloat textViewWidth;
    NSInteger currentPhotoIdx;
    UITextField *beginYearTextField;
    UITextField *endYearTextField;
    UITextField *dateTextField;
    UIButton *_ceButton;
    UIButton *_bceButton;
    UIButton *_ceBeginButton;
    UIButton *_bceBeginButton;
    UIButton *_ceEndButton;
    UIButton *_bceEndButton;
}
@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) Favorite *favorite;
@property (strong, nonatomic) UIPopoverController *popover;
@end

@implementation WFArtMetadataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (SYSTEM_VERSION >= 8.f){
        iOS8 = YES;
        width = screenWidth();
        height = screenHeight();
    } else {
        iOS8 = NO;
        width = screenWidth();
        height = screenHeight();
    }
    self.automaticallyAdjustsScrollViewInsets = NO;
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    rowHeight = 60.f;
    textViewWidth = width - 160.f; // 160.f is a spacer
    editMode = NO;
    [self setupDateFormatter];
    [self registerForKeyboardNotifications];
    self.photo = [self.photo MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    [self loadPhotoMetadata];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    textViewWidth = self.view.frame.size.width - 160.f; // 160.f is a spacer
    [self setupHeader];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    originalViewFrame = self.view.frame;
    originalNavFrame = self.navigationController.view.frame;
}

- (void)setupDateFormatter {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
}

- (void)setupHeader {
    CGSize viewSize = self.view.frame.size;
    self.tableView.tableHeaderView = _topImageContainerView;
    currentPhotoIdx = [self.photo.art.photos indexOfObject:self.photo];
    [self setPhotoCount:currentPhotoIdx+1]; // setPhotoCredit called at the end of setPhotoCount... no worries
    
    [_dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    CGRect dismissFrame = self.dismissButton.frame;
    dismissFrame.origin.x = viewSize.width-dismissFrame.size.width;
    [self.dismissButton setFrame:dismissFrame];
    
    [self setUpButtons];
    [_nextPhotoButton addTarget:self action:@selector(nextPhoto) forControlEvents:UIControlEventTouchUpInside];
    [_lastPhotoButton addTarget:self action:@selector(lastPhoto) forControlEvents:UIControlEventTouchUpInside];
    [self.photoCountLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    
    if (IDIOM == IPAD){
        
    } else {
        if (viewSize.width > viewSize.height){
            [_favoriteButton setHidden:NO];
            [_dropToTableButton setHidden:NO];
            [_flagButton setHidden:NO];
            [_tagButton setHidden:NO];
            [_editButton setHidden:NO];
            [_deleteButton setHidden:NO];
            [_postedByButton setHidden:NO];
            if (self.photo.art.photos.count > 1){
                [_photoCountLabel setHidden:NO];
                [_nextPhotoButton setHidden:NO];
                [_lastPhotoButton setHidden:NO];
            }
            landscape = YES;
        } else {
            [_favoriteButton setHidden:YES];
            [_dropToTableButton setHidden:YES];
            [_flagButton setHidden:YES];
            [_tagButton setHidden:YES];
            [_editButton setHidden:YES];
            [_deleteButton setHidden:YES];
            [_postedByButton setHidden:YES];
            [_photoCountLabel setHidden:YES];
            [_nextPhotoButton setHidden:YES];
            [_lastPhotoButton setHidden:YES];
            landscape = NO;
        }
    }
    
    [self setupPhotoScrollView];
}

- (void)setPhotoCount:(NSInteger)currentIdx{
    CGFloat landscapeWidth = IDIOM == IPAD ? 380.f : width;
    
    if (self.photo.art.photos.count == 1){
        [self.photoCountLabel setText:@"1 photo"];
    } else {
        [self.photoCountLabel setText:[NSString stringWithFormat:@"%ld of %lu photos",(long)currentIdx, (unsigned long)self.photo.art.photos.count]];
    }
    if (self.photo.art.photos.count <= 1){
        [_nextPhotoButton setHidden:YES];
        [_lastPhotoButton setHidden:YES];
    } else if (landscape) {
        [_nextPhotoButton setHidden:NO];
        [_lastPhotoButton setHidden:NO];
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
    [self.photoScrollView setBackgroundColor:[UIColor clearColor]];
    self.photoScrollView.delegate = self;
    self.photoScrollView.pagingEnabled = YES;
    [self.photoScrollView setCanCancelContentTouches:YES];
    NSInteger idx = 0;
    CGFloat landscapeWidth, landscapeHeight, portraitWidth, portraitHeight;
    if (landscape){
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
        [imageButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [imageButton setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [imageButton setShowsTouchWhenHighlighted:NO];
        [imageButton setAdjustsImageWhenHighlighted:NO];
        imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageButton.imageView.layer.cornerRadius = 3.f;
        imageButton.imageView.layer.backgroundColor = [UIColor clearColor].CGColor;
        imageButton.imageView.clipsToBounds = YES;
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
        
        if (!imageButton.imageView.image){
            [imageButton setAlpha:0.0];
        }
        
        [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:photo.slideImageUrl] options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            [_progressIndicator setProgress:((CGFloat)receivedSize / (CGFloat)expectedSize)];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            [imageButton setImage:image forState:UIControlStateNormal];
            [UIView animateWithDuration:.23 animations:^{
                [imageButton setAlpha:1.0];
            } completion:^(BOOL finished) {
                [_progressIndicator removeFromSuperview];
                imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
                imageButton.imageView.layer.shouldRasterize = YES;
                //NSLog(@"image button width: %@", imageButton);
            }];
        }];
        [imageButton addTarget:self action:@selector(showFullScreen) forControlEvents:UIControlEventTouchUpInside];
        idx ++;
    }
    
    [self.photoScrollView setContentSize:CGSizeMake(self.photo.art.photos.count * landscapeWidth, landscapeWidth)]; //  use 380 as a max
    [self.photoScrollView setContentOffset:CGPointMake(landscapeWidth * currentPhotoIdx, 0) animated:YES];
}

- (void)setPhotoCredit {
    if (self.photo.user && self.photo.user.fullName.length){
        NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        [_postedByButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
        NSMutableAttributedString *postedByString = [[NSMutableAttributedString alloc] initWithString:@"POSTED BY:" attributes:@{NSFontAttributeName : [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor blackColor],NSParagraphStyleAttributeName:paragraphStyle}];
        NSMutableAttributedString *postedByUserString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@",self.photo.user.fullName] attributes:@{NSFontAttributeName : [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSans] size:0], NSForegroundColorAttributeName : kElectricBlue,NSParagraphStyleAttributeName:paragraphStyle}];
        [postedByString appendAttributedString:postedByUserString];
        [_postedByButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [_postedByButton setContentVerticalAlignment:UIControlContentVerticalAlignmentBottom];
        [_postedByButton setAttributedTitle:postedByString forState:UIControlStateNormal];
        [_postedByButton addTarget:self action:@selector(showProfile) forControlEvents:UIControlEventTouchUpInside];
        [_postedByButton.titleLabel setNumberOfLines:0];
        
        if (IDIOM == IPAD){
            [_postedByButton setHidden:NO];
        } else if (landscape){
            [_postedByButton setHidden:NO];
        } else {
            [_postedByButton setHidden:YES];
        }
    } else {
        [_postedByButton setHidden:YES];
    }
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:6 inSection:0],[NSIndexPath indexPathForRow:7 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)nextPhoto {
    CGFloat orientationWidth = landscape ? height : width; // depends on orientation, since the iPhone rotates
    CGFloat landscapeWidth = IDIOM == IPAD ? 380.f : orientationWidth;
    [self.photoScrollView setContentOffset:CGPointMake(self.photoScrollView.contentOffset.x + landscapeWidth, 0) animated:YES];
    currentPhotoIdx ++;
}

- (void)lastPhoto {
    CGFloat orientationWidth = landscape ? height : width; // depends on orientation, since the iPhone rotates
    CGFloat landscapeWidth = IDIOM == IPAD ? 380.f : orientationWidth;
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
                [self presentViewController:nav animated:YES completion:^{
                    
                }];
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
    //refetch the light table
    LightTable *lightTable = [l MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    [lightTable addPhoto:self.photo];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    //ensure we're playing with a real light table first
    if (![lightTable.identifier isEqualToNumber:@0]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:self.photo.identifier forKey:@"photo_id"];
        [manager POST:[NSString stringWithFormat:@"light_tables/%@/add",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success dropping metadata photo to light table: %@",responseObject);
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
    [self.tableView reloadData];
    if (editMode){
        CGRect newViewFrame = originalViewFrame;
        if (iOS8){
            newViewFrame.origin.y = 0;
            newViewFrame.origin.x -= 100;
            newViewFrame.size.width += 200;
        } else {
            newViewFrame.origin.x = 0;
            newViewFrame.origin.y -= 100;
            newViewFrame.size.height += 200;
        }
        CGRect navFrame = self.navigationController.view.frame;
        navFrame.size.width = newViewFrame.size.width;
        navFrame.origin.x = (width-navFrame.size.width)/2;
        [self.navigationController.view setFrame:navFrame];
        self.tableView.tableFooterView = saveContainerView;
        [UIView animateWithDuration:.77 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.view setFrame:newViewFrame];
            
            [_nextPhotoButton setAlpha:0.0];
            [_lastPhotoButton setAlpha:0.0];
            if (iOS8){
                [saveButton setFrame:CGRectMake(20, 13, newViewFrame.size.width-40, 44)];
            } else {
                [saveButton setFrame:CGRectMake(20, 13, newViewFrame.size.height-40, 44)];
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
        [UIView animateWithDuration:.77 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.view setFrame:originalViewFrame];
            [self.navigationController.view setFrame:originalNavFrame];
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
    WFProfileViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
    [vc setUser:self.photo.user];
    [self resetTransitionBooleans];
    profile = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if (IDIOM == IPAD){
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
    }
    
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)loadPhotoMetadata {
    if (![self.photo.identifier isEqualToNumber:@0]){
        [manager GET:[NSString stringWithFormat:@"photos/%@",self.photo.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success fetching metadata: %@",responseObject);
            if ([responseObject objectForKey:@"text"]){
                if ([[responseObject objectForKey:@"text"] isEqualToString:kNoPhoto]){
                    [self.photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                    [WFAlert show:@"Sorry, but something went wrong while trying to fetch this art.\n\nThe creator likely expunged it from our database." withTime:3.7f];
                    if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(photoDeleted:)]){
                        [self.metadataDelegate photoDeleted:self.photo];
                    }
                    
                } else if ([[responseObject objectForKey:@"text"] isEqualToString:kArtDeleted]){
                    [self.photo.art MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                    if (self.metadataDelegate && [self.metadataDelegate respondsToSelector:@selector(artDeleted:)]){
                        [self.metadataDelegate artDeleted:self.photo.art];
                    }
                }
                [self dismiss];
            } else {
                [self.photo populateFromDictionary:[responseObject objectForKey:@"photo"]];
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    [self setupHeader];
                    [self.tableView reloadData];
                }];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error fetching art metadata: %@",error.description);
        }];
    }
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
    [photoParameters setObject:@(privateSwitch.isOn) forKey:@"private"];
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
        if (self.photo.art.interval.suffix && self.photo.art.interval.suffix.length){
            [artParameters setObject:self.photo.art.interval.suffix forKey:@"interval[suffix]"];
        }
        if (self.photo.art.interval.beginSuffix && self.photo.art.interval.beginSuffix.length){
            [artParameters setObject:self.photo.art.interval.beginSuffix forKey:@"interval[begin_suffix]"];
        }
        if (self.photo.art.interval.endSuffix && self.photo.art.interval.endSuffix.length){
            [artParameters setObject:self.photo.art.interval.endSuffix forKey:@"interval[end_suffix]"];
        }
    }
    
    [manager PATCH:[NSString stringWithFormat:@"photos/%@",self.photo.identifier] parameters:@{@"photo":photoParameters,@"art":artParameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success saving metadata: %@",responseObject);
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
    textViewWidth = iOS8 ? self.view.frame.size.width - 160.f : self.view.frame.size.height - 160.f; // 160.f is a spacer
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
    [cell.textView setHidden:NO];
    [cell.notesTextView setHidden:YES];
    
    switch (indexPath.row) {
        case 0:
            [cell.label setText:@"TITLE"];
            [cell.textView setText:self.photo.art.title];
            titleTextView = cell.textView;
            break;
        case 1:
        {
            [cell.label setText:@"ARTIST(S)"];
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
                
                _ceButton = dateCell.ceButton;
                [dateCell.ceButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
                _bceButton = dateCell.bceButton;
                [dateCell.bceButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
                
                _ceBeginButton = dateCell.ceBeginButton;
                [dateCell.ceBeginButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
                _ceEndButton = dateCell.ceEndButton;
                [dateCell.ceEndButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
                
                _bceBeginButton = dateCell.bceBeginButton;
                [dateCell.bceBeginButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
                _bceEndButton = dateCell.bceEndButton;
                [dateCell.bceEndButton addTarget:self action:@selector(eraTapped:) forControlEvents:UIControlEventTouchUpInside];
                return dateCell;
            } else {
                [cell.label setText:@"DATE"];
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
            [cell.textView setHidden:YES];
            [cell.notesTextView setHidden:NO];
            notesTextView = cell.notesTextView;
            CGRect notesRect = cell.notesTextView.frame;
            notesRect.size.width = textViewWidth;
            if (self.photo.art.notes.length){
                [cell.notesTextView setText:self.photo.art.notes];
                CGSize size = [cell.notesTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
                notesRect.size.height = size.height;
                CGFloat comparisonHeight = notesRect.size.height + 23.f > rowHeight ? notesRect.size.height + 23.f : rowHeight;
                notesRect.origin.y = comparisonHeight/2-notesRect.size.height/2;
            } else {
                notesRect.origin.y = 0;
                notesRect.size.height = rowHeight;
            }
            
            [cell.notesTextView setFrame:notesRect];
            break;
        case 9:
            [cell.label setText:@"PRIVATE"];
            [cell.privateSwitch setHidden:NO];
            privateSwitch = cell.privateSwitch;
            [privateSwitch setOn:self.photo.privatePhoto.boolValue];
            [privateSwitch addTarget:self action:@selector(privateSwitchSwitched:) forControlEvents:UIControlEventValueChanged];
            [cell.textView setHidden:YES];
            break;
            
        default:
            break;
    }
    
    // fancy text fade in
    [UIView animateWithDuration:kFastAnimationDuration animations:^{
        if (indexPath.row == 7 && cell.notesTextView.text.length){
            [cell.notesTextView setAlpha:1.0];
        } else if (cell.textView.text.length) {
            [cell.textView setAlpha:1.0];
        }
    }];
    
    //size the text view appropriately
    [cell.textView sizeToFit];
    CGRect textViewRect = cell.textView.frame;
    textViewRect.size.width = textViewWidth;
    CGFloat comparisonHeight = cell.textView.frame.size.height > rowHeight ? cell.textView.frame.size.height : rowHeight;
    textViewRect.origin.y = comparisonHeight/2-textViewRect.size.height/2;
    [cell.textView setFrame:textViewRect];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITextView *sizingTextView = [[UITextView alloc] init];
    [sizingTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    
    if (indexPath.row == 0){
        [sizingTextView setText:self.photo.art.title];
        CGSize size = [sizingTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        CGFloat newRowHeight = size.height > rowHeight ? size.height : rowHeight;
        sizingTextView = nil;
        return newRowHeight;
    } else if (indexPath.row == 1){
        [sizingTextView setText:self.photo.art.artistsToSentence];
        CGSize size = [sizingTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        CGFloat newRowHeight = size.height > rowHeight ? size.height : rowHeight;
        sizingTextView = nil;
        return newRowHeight;
    } else if (indexPath.row == 2){
        if (editMode){
            return 110.f;
        } else {
            return rowHeight;
        }
    } else if (indexPath.row == 3){
        [sizingTextView setText:self.photo.art.tagsToSentence];
        CGSize size = [sizingTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        CGFloat newRowHeight = size.height > rowHeight ? size.height : rowHeight;
        sizingTextView = nil;
        return newRowHeight;
    } else if (indexPath.row == 4){
        [sizingTextView setText:self.photo.art.materialsToSentence];
        CGSize size = [sizingTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        CGFloat newRowHeight = size.height > rowHeight ? size.height : rowHeight;
        sizingTextView = nil;
        return newRowHeight;
    } else if (indexPath.row == 5){
        [sizingTextView setText:[self.photo iconsToSentence]];
        CGSize size = [sizingTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        CGFloat newRowHeight = size.height > rowHeight ? size.height : rowHeight;
        sizingTextView = nil;
        return newRowHeight;
    } else if (indexPath.row == 6){
        [sizingTextView setText:self.photo.art.locationsToSentence];
        CGSize size = [sizingTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        CGFloat newRowHeight = size.height > rowHeight ? size.height : rowHeight;
        sizingTextView = nil;
        return newRowHeight;
    } else if (indexPath.row == 7){
        [sizingTextView setText:self.photo.credit];
        CGSize size = [sizingTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        CGFloat newRowHeight = size.height > rowHeight ? size.height : rowHeight;
        sizingTextView = nil;
        return newRowHeight;
    } else if (indexPath.row == 8) {
        if (self.photo.art.notes.length){
            [sizingTextView setText:self.photo.art.notes];
            CGSize size = [sizingTextView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
            CGFloat newRowHeight = size.height + 23.f > rowHeight ? size.height + 23.f : rowHeight;
            sizingTextView = nil;
            return newRowHeight;
        } else {
            return rowHeight;
        }
    } else {
        return rowHeight;
    }
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
    nav.modalPresentationStyle = UIModalPresentationCustom;
    nav.transitioningDelegate = self;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)artistsSelected:(NSOrderedSet *)selectedArtists {
    self.photo.art.artists = selectedArtists;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)showLocations {
    [self resetTransitionBooleans];
    metadataModal = YES;
    WFLocationsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Locations"];
    [vc setSelectedLocations:self.photo.art.locations.mutableCopy];
    vc.locationDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)locationsSelected:(NSOrderedSet *)selectedLocations {
    self.photo.art.locations = selectedLocations;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)communityTag {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [self resetTransitionBooleans];
        metadataModal = YES;
        WFTagsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Tags"];
        [vc setCommunityTagMode:YES];
        [vc setArt:self.photo.art];
        [vc setSelectedTags:[NSMutableOrderedSet orderedSet]];
        vc.tagDelegate = self;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:nav animated:YES completion:NULL];
    } else {
        [self showLogin];
    }
}

- (void)showTags {
    [self resetTransitionBooleans];
    metadataModal = YES;
    WFTagsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Tags"];
    [vc setCommunityTagMode:NO];
    [vc setArt:self.photo.art];
    [vc setSelectedTags:self.photo.art.tags.mutableCopy];
    vc.tagDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)tagsSelected:(NSOrderedSet *)selectedTags {
    self.photo.art.tags = selectedTags;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:4 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)showMaterials {
    [self resetTransitionBooleans];
    metadataModal = YES;
    WFMaterialsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Materials"];
    [vc setSelectedMaterials:self.photo.art.materials.mutableCopy];
    vc.materialDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)materialsSelected:(NSOrderedSet *)selectedMaterials {
    self.photo.art.materials = selectedMaterials;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:5 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }];
    
}

- (void)showIcons {
    [self resetTransitionBooleans];
    metadataModal = YES;
    WFIconsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Icons"];
    [vc setSelectedIcons:self.photo.icons.mutableCopy];
    vc.iconsDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
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
    UIActionSheet *flagActionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Why do you want to flag \"%@\"?",self.photo.art.title] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Inappropriate", @"Copyright", @"Incorrect metadata", nil];
    flagActionSheet.tintColor = kElectricBlue;
    [flagActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Inappropriate"]){
        [self flag];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Copyright"]) {
        [self performSegueWithIdentifier:@"Flag" sender:kCopyright];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Incorrect metadata"]) {
        [self performSegueWithIdentifier:@"Flag" sender:nil];
    }
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        landscape = size.width > size.height ? YES : NO;
        width = size.width; height = size.height;
        
        if (IDIOM != IPAD){
            CGRect dismissFrame = self.dismissButton.frame;
            dismissFrame.origin.x = size.width-dismissFrame.size.width;
            [self.dismissButton setFrame:dismissFrame];
            if (size.width > size.height){
                [_favoriteButton setHidden:NO];
                [_dropToTableButton setHidden:NO];
                [_flagButton setHidden:NO];
                [_tagButton setHidden:NO];
                [_editButton setHidden:NO];
                [_deleteButton setHidden:NO];
                [_postedByButton setHidden:NO];
                if (self.photo.art.photos.count > 1){
                    [_photoCountLabel setHidden:NO];
                    [_nextPhotoButton setHidden:NO];
                    [_lastPhotoButton setHidden:NO];
                }
            } else {
                [_favoriteButton setHidden:YES];
                [_dropToTableButton setHidden:YES];
                [_flagButton setHidden:YES];
                [_tagButton setHidden:YES];
                [_editButton setHidden:YES];
                [_deleteButton setHidden:YES];
                [_postedByButton setHidden:YES];
                [_photoCountLabel setHidden:YES];
                [_nextPhotoButton setHidden:YES];
                [_lastPhotoButton setHidden:YES];
            }
            [self setupPhotoScrollView];
        }
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

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
    if (button == _ceButton){
        [_ceButton setSelected:YES];
        [_bceButton setSelected:NO];
        [self.photo.art.interval setSuffix:@"CE"];
    } else if (button == _bceButton){
        [_bceButton setSelected:YES];
        [_ceButton setSelected:NO];
        [self.photo.art.interval setSuffix:@"BCE"];
    } else if (button == _ceBeginButton){
        [_bceBeginButton setSelected:NO];
        [_ceBeginButton setSelected:YES];
        [self.photo.art.interval setBeginSuffix:@"CE"];
    } else if (button == _bceBeginButton){
        [_bceBeginButton setSelected:YES];
        [_ceBeginButton setSelected:NO];
        [self.photo.art.interval setBeginSuffix:@"BCE"];
    } else if (button == _ceEndButton){
        [_bceEndButton setSelected:NO];
        [_ceEndButton setSelected:YES];
        [self.photo.art.interval setEndSuffix:@"CE"];
    } else if (button == _bceEndButton){
        [_bceEndButton setSelected:YES];
        [_ceEndButton setSelected:NO];
        [self.photo.art.interval setEndSuffix:@"BCE"];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
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
        if (keyboardUp){
            [self.view endEditing:YES];
        } else {
            [self.view endEditing:YES];
            [self edit];
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{ // ensure the dismiss happens RIGHT NOW
            [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
        });
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
