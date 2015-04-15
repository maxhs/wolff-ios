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

@interface WFSlideshowSettingsViewController () <UIAlertViewDelegate> {
    UIAlertView *confirmDeletionAlertView;
    UISwitch *slideshowVisibilitySwitch;
    UISwitch *showTitleSlideSwitch;
    BOOL shouldSave;
}
@end

@implementation WFSlideshowSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.1]];
    self.tableView.rowHeight = 54.f;
    self.slideshow = [self.slideshow MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    slideshowVisibilitySwitch = [[UISwitch alloc] init];
    showTitleSlideSwitch = [[UISwitch alloc] init];}

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
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFSlideshowSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SlideshowSettingsCell" forIndexPath:indexPath];
    [cell.centerImageView setHidden:YES];
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
            break;
        case 1:
            [cell.textLabel setText:@""];
            CGRect centerRect = cell.centerImageView.frame;
            centerRect.origin.x = cell.frame.size.width/2-(centerRect.size.width/2);
            centerRect.origin.y = cell.frame.size.height/2-(centerRect.size.height/2);
            [cell.centerImageView setFrame:centerRect];
            [cell.centerImageView setHidden:NO];
            [cell.centerImageView setImage:[UIImage imageNamed:@"trash"]];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
