//
//  WFSlideshowSettingsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/2/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSlideshowSettingsViewController.h"
#import "WFSlideshowSettingsCell.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "Constants.h"
#import "WFUtilities.h"

@interface WFSlideshowSettingsViewController () <UIAlertViewDelegate> {
    UIAlertView *confirmDeletionAlertView;
    UISwitch *slideshowVisibilitySwitch;
    UISwitch *showTitleSlideSwitch;
    UISwitch *showMetadataSwitch;
    BOOL shouldSave;
    UIImageView *navBarShadowView;
}
@end

@implementation WFSlideshowSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.07]];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    self.tableView.rowHeight = 54.f;
    self.slideshow = [self.slideshow MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    slideshowVisibilitySwitch = [[UISwitch alloc] init];
    showTitleSlideSwitch = [[UISwitch alloc] init];
    showMetadataSwitch = [[UISwitch alloc] init];
    
    if (IDIOM == IPAD){
        
    } else {
        UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        self.navigationItem.leftBarButtonItem = dismissButton;
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
        [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
        [backgroundToolbar setTranslucent:YES];
        [self.tableView setBackgroundView:backgroundToolbar];
    }
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)confirmDeletion {
    confirmDeletionAlertView = [[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:@"Are you sure you want to delete this slideshow?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil];
    [confirmDeletionAlertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == confirmDeletionAlertView && [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]){
        [self delete];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFSlideshowSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SlideshowSettingsCell" forIndexPath:indexPath];
    [cell.centerImageView setHidden:YES];
    [cell.textLabel setTextColor:(IDIOM == IPAD) ? [UIColor blackColor] : [UIColor whiteColor]];
    switch (indexPath.row) {
//        case 0:
//            [cell.imageView setImage:nil];
//            [cell.textLabel setText:@"Public"];
//            cell.accessoryView = slideshowVisibilitySwitch;
//            [slideshowVisibilitySwitch setOn:[_slideshow.visible boolValue]];
//            [slideshowVisibilitySwitch addTarget:self action:@selector(switchSwitched:) forControlEvents:UIControlEventValueChanged];
//            break;
        case 0:
            [cell.imageView setImage:nil];
            [cell.textLabel setText:@"Show title slide"];
            cell.accessoryView = showTitleSlideSwitch;
            [showTitleSlideSwitch setOn:[_slideshow.showTitleSlide boolValue]];
            [showTitleSlideSwitch addTarget:self action:@selector(switchSwitched:) forControlEvents:UIControlEventValueChanged];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            break;
        case 1:
            [cell.imageView setImage:nil];
            [cell.textLabel setText:@"Show metadata"];
            cell.accessoryView = showMetadataSwitch;
            [showMetadataSwitch setOn:[_slideshow.showMetadata boolValue]];
            [showMetadataSwitch addTarget:self action:@selector(switchSwitched:) forControlEvents:UIControlEventValueChanged];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            break;
        case 2:
            [cell.textLabel setText:@""];
            CGRect centerRect = cell.centerImageView.frame;
            centerRect.origin.x = cell.frame.size.width/2-(centerRect.size.width/2);
            centerRect.origin.y = cell.frame.size.height/2-(centerRect.size.height/2);
            [cell.centerImageView setFrame:centerRect];
            [cell.centerImageView setHidden:NO];
            [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
            [cell.centerImageView setImage:(IDIOM == IPAD) ? [UIImage imageNamed:@"trash"] : [UIImage imageNamed:@"whiteTrash"]];
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (void)switchSwitched:(UISwitch*)theSwitch {
    if (theSwitch == showTitleSlideSwitch){
        [self.slideshow setShowTitleSlide:@(theSwitch.isOn)];
        shouldSave = YES;
    } else if (theSwitch == showMetadataSwitch){
        [self.slideshow setShowMetadata:@(theSwitch.isOn)];
        shouldSave = YES;
    } else if (theSwitch == slideshowVisibilitySwitch){
        [self.slideshow setVisible:@(theSwitch.isOn)];
        shouldSave = YES;
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    /*if (indexPath.row == 0){
        shouldSave = YES;
        NSNumber *visibilityOpposite = self.slideshow.visible.boolValue ? @0 : @1;
        [self.slideshow setVisible:visibilityOpposite];
        [slideshowVisibilitySwitch setOn:self.slideshow.visible.boolValue animated:YES];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    } else*/ if (indexPath.row == 0){
        shouldSave = YES;
        NSNumber *showTitleOpposite = self.slideshow.showTitleSlide.boolValue ? @0 : @1;
        [self.slideshow setShowTitleSlide:showTitleOpposite];
        [showTitleSlideSwitch setOn:self.slideshow.showTitleSlide.boolValue animated:YES];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    } else if (indexPath.row == 1){
        shouldSave = YES;
        NSNumber *showMetadataOpposite = self.slideshow.showMetadata.boolValue ? @0 : @1;
        [self.slideshow setShowMetadata:showMetadataOpposite];
        [showMetadataSwitch setOn:self.slideshow.showMetadata.boolValue animated:YES];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    } else if (indexPath.row == 2){
        [self confirmDeletion];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)delete{
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(didDeleteSlideshow)]){
        [self.settingsDelegate didDeleteSlideshow];
    }
}

- (void)updateSlideshow {
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(didUpdateSlideshow)]){
        [self.settingsDelegate didUpdateSlideshow];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (shouldSave){
        [self updateSlideshow];
    }
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Dispose of any resources that can be recreated.
}

@end
