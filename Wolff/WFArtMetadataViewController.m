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
#import <SDWebImage/UIButton+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface WFArtMetadataViewController () <UITextViewDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    NSDateFormatter *dateFormatter;
    User *_currentUser;
    Favorite *_favorite;
    BOOL editMode;
    CGFloat keyboardHeight;
    UITextView *titleTextView;
    UITextView *notesTextView;
    CGRect originalViewFrame;
    UIView *saveContainerView;
    UIButton *saveButton;
    UIImageView *navBarShadowView;
}

@end

@implementation WFArtMetadataViewController

@synthesize art = _art;

- (void)viewDidLoad
{
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    editMode = NO;
    [self setupDateFormatter];
    [self registerForKeyboardNotifications];
    
    [self loadArtMetadata];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    [_topImageView setBackgroundColor:kSlideBackgroundColor];
    _topImageView.layer.cornerRadius = 3.f;
    _topImageView.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.tableView.tableHeaderView = _topImageContainerView;
    [_topImageView setAlpha:0.0];
    [_topImageView sd_setImageWithURL:[NSURL URLWithString:_art.photo.largeImageUrl] placeholderImage:nil/*[UIImage imageNamed:@"transparentIcon"]*/ completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [UIView animateWithDuration:.23 animations:^{
            [_topImageView setBackgroundColor:[UIColor whiteColor]];
            [_topImageView setAlpha:1.0];
        } completion:^(BOOL finished) {
            [_topImageView.layer setShouldRasterize:YES];
            _topImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        }];
        
    }];
    
    [_backButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self setUpButtons];
    [self setPostedCredit];
}

- (void)setPostedCredit {
    if (_art.user){
        [_postedByButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
        [_postedByButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_postedByButton setTitle:[NSString stringWithFormat:@"Posted: %@",_art.user.fullName] forState:UIControlStateNormal];
        [_postedByButton addTarget:self action:@selector(showProfile) forControlEvents:UIControlEventTouchUpInside];
        [_postedByButton setHidden:NO];
    } else {
        [_postedByButton setHidden:YES];
    }
}

- (void)setUpButtons {
    [_flagButton addTarget:self action:@selector(flag) forControlEvents:UIControlEventTouchUpInside];
    [_flagButton setImage:[UIImage imageNamed:@"flag"] forState:UIControlStateNormal];
    [_flagButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
    [_flagButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    
    [_dropToTableButton addTarget:self action:@selector(dropToLightTable) forControlEvents:UIControlEventTouchUpInside];
    [_dropToTableButton setImage:[UIImage imageNamed:@"dropToLightTable"] forState:UIControlStateNormal];
    [_dropToTableButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
    [_dropToTableButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    
    if (_currentUser && [_art.user.identifier isEqualToNumber:_currentUser.identifier]){
        [_editButton addTarget:self action:@selector(edit) forControlEvents:UIControlEventTouchUpInside];
        [_editButton setImage:[UIImage imageNamed:@"edit"] forState:UIControlStateNormal];
        [_editButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
        [_editButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
        [_editButton setHidden:NO];
        
        saveContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 70)];
        [saveContainerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [saveContainerView setBackgroundColor:[UIColor whiteColor]];
        
        saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [saveContainerView addSubview:saveButton];
        [saveButton setFrame:CGRectMake(20, 13, saveContainerView.frame.size.width-40, 44)];
        [saveButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
        [saveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [saveButton addTarget:self action:@selector(saveMetadata) forControlEvents:UIControlEventTouchUpInside];
        [saveButton setTitle:@"SAVE" forState:UIControlStateNormal];
        saveButton.layer.cornerRadius = 7.f;
        saveButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
        saveButton.layer.borderWidth = .5f;
        
    } else {
        [_editButton setHidden:YES];
    }
    
    [_favoriteButton setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
    [_favoriteButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    _favorite = [_currentUser getFavorite:_art];
    if (_currentUser && _favorite){
        [_favoriteButton setTitle:@"   Favorited!" forState:UIControlStateNormal];
        [_favoriteButton addTarget:self action:@selector(unfavorite) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [_favoriteButton addTarget:self action:@selector(favorite) forControlEvents:UIControlEventTouchUpInside];
        [_favoriteButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.023]];
    }
}

- (void)dropToLightTable {
    
}

- (void)edit {
    editMode = editMode ? NO : YES;
    [self.tableView reloadData];
    if (editMode){
        CGRect newViewFrame = originalViewFrame;
        newViewFrame.origin.y = 10;
        newViewFrame.origin.x -= 100;
        newViewFrame.size.width += 200;
        self.tableView.tableFooterView = saveContainerView;
        [UIView animateWithDuration:.77 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.view setFrame:newViewFrame];
            [saveButton setFrame:CGRectMake(20, 13, newViewFrame.size.width-40, 44)];
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

- (void)showProfile {
    NSLog(@"Should be showing profile");
}

- (void)loadArtMetadata {
    [manager GET:[NSString stringWithFormat:@"arts/%@",_art.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success fetching metadata: %@",responseObject);
        [_art populateFromDictionary:[responseObject objectForKey:@"art"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self setupHeader];
            [self.tableView reloadData];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching art metadata: %@",error.description);
    }];
}

- (void)saveMetadata {
    _art.notes = notesTextView.text;
    _art.title = titleTextView.text;
    [ProgressHUD show:@"Saving..."];
    [self.view endEditing:YES];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:_art.title forKey:@"title"];
    [parameters setObject:_art.notes forKey:@"notes"];
    [manager PATCH:[NSString stringWithFormat:@"arts/%@",_art.identifier] parameters:@{@"art":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success saving metadata: %@",responseObject);
        [_art populateFromDictionary:[responseObject objectForKey:@"art"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD dismiss];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error saving metadata: %@",error.description);
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD dismiss];
        }];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 8;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFArtMetadataCell *cell = (WFArtMetadataCell *)[tableView dequeueReusableCellWithIdentifier:@"ArtMetadataCell"];
    [cell setDefaultStyle:editMode];
    cell.textView.delegate = self;
    [cell.textView setKeyboardAppearance:UIKeyboardAppearanceDark];
    
    switch (indexPath.row) {
        case 0:
            [cell.label setText:@"TITLE"];
            [cell.textView setText:_art.title];
            titleTextView = cell.textView;
            break;
        case 1:
        {
            [cell.label setText:@"ARTIST(S)"];
            NSString *artists = [_art artistsToSentence];
            if (artists.length > 1){
                [cell.textView setText:artists];
            } else {
                [cell.textView setText:@"Artist(s) unknown..."];
                [cell.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textView setTextColor:[UIColor lightGrayColor]];
            }
        }
            break;
        case 2:
            [cell.label setText:@"DATE"];
            //NSLog(@"art interval: %@",_art.interval);
            if (_art.interval.single){
                [cell.textView setText:[dateFormatter stringFromDate:_art.interval.single]];
            } else if (![_art.interval.beginRange isEqualToNumber:@0] && ![_art.interval.endRange isEqualToNumber:@0]) {
                NSString *beginSuffix = _art.interval.beginSuffix.length ? _art.interval.beginSuffix : @"CE";
                NSString *endSuffix = _art.interval.endSuffix.length ? _art.interval.endSuffix : @"CE";
                [cell.textView setText:[NSString stringWithFormat:@"%@ %@ - %@ %@",_art.interval.beginRange, beginSuffix, _art.interval.endRange, endSuffix]];
            } else if (![_art.interval.year isEqualToNumber:@0]){
                NSString *suffix = _art.interval.suffix.length ? _art.interval.suffix : @"CE";
                [cell.textView setText:[NSString stringWithFormat:@"%@ %@",_art.interval.year, suffix]];
            } else {
                [cell.textView setText:@"No date listed"];
                [cell.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textView setTextColor:[UIColor lightGrayColor]];
            }
            break;
        case 3:
        {
            [cell.label setText:@"MATERIAL(S)"];
            NSString *materials = [_art materialsToSentence];
            if (materials.length){
                [cell.textView setText:materials];
            } else {
                [cell.textView setText:@"No materials listed"];
                [cell.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textView setTextColor:[UIColor lightGrayColor]];
            }
        }
            break;
        case 4:
        {
            [cell.label setText:@"LOCATION"];
            NSString *locations = [_art locationsToSentence];
            
            if (locations.length){
                [cell.textView setText:locations];
            } else {
                [cell.textView setText:@"No locations listed"];
                [cell.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textView setTextColor:[UIColor lightGrayColor]];
            }
        }
            break;
        case 5:
        {
            [cell.label setText:@"ICONOGRAPHY"];
            NSString *icons = [_art iconsToSentence];
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
            [cell.label setText:@"LICENSE"];
            [cell.textView setText:@"Public Domain"];
            break;
        case 7:
            [cell.label setText:@"NOTES"];
            [cell.textView setText:@""];
            notesTextView = cell.textView;
            CGRect notesRect = cell.textView.frame;
            CGFloat cellHeight = cell.frame.size.height;
            CGFloat minHeight = cellHeight-14 > 86 ? cellHeight-14 : 86;
            notesRect.size.height = minHeight;
            [cell.textView setFrame:notesRect];
            [cell.textView setText:_art.notes];
            break;
            
        default:
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 7) {
        return 100;
    } else {
        return 54;
    }
}

- (void)favorite {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [manager POST:[NSString stringWithFormat:@"arts/%@/favorite",_art.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success posting favorite: %@",responseObject);
            _favorite = [Favorite MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [_favorite populateFromDictionary:[responseObject objectForKey:@"favorite"]];
            
            [_favoriteButton setTitle:@"  Favorited!" forState:UIControlStateNormal];
            [_favoriteButton removeTarget:nil
                               action:NULL
                     forControlEvents:UIControlEventAllEvents];
            [_favoriteButton addTarget:self action:@selector(unfavorite) forControlEvents:UIControlEventTouchUpInside];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to favorite %@: %@",_art.title,error.description);
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
            
            [_favoriteButton setTitle:@"   Add to favorites" forState:UIControlStateNormal];
            [_favoriteButton removeTarget:nil
                                   action:NULL
                         forControlEvents:UIControlEventAllEvents];
            [_favoriteButton addTarget:self action:@selector(favorite) forControlEvents:UIControlEventTouchUpInside];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to unfavorite %@: %@",_art.title,error.description);
        }];
    } else {
        [self showLogin];
    }
}

- (void)showLogin {
    
}

- (void)flag {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:_art.identifier forKey:@"art_id"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    [manager POST:[NSString stringWithFormat:@"flags"] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a flag for %@, %@",_art.identifier, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to create a flag: %@",error.description);
    }];
}

- (void)registerForKeyboardNotifications
{
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
    NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
    keyboardHeight = keyboardValue.CGRectValue.size.height;
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
