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

@interface WFSlideshowSettingsViewController () <UIAlertViewDelegate> {
    UIAlertView *confirmDeletionAlertView;
    UISwitch *presentationVisibilitySwitch;
    Presentation *_presentation;
}

@end

@implementation WFSlideshowSettingsViewController
@synthesize presentationId = _presentationId;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.1]];
    
    _presentation = [Presentation MR_findFirstByAttribute:@"identifier" withValue:_presentationId inContext:[NSManagedObjectContext MR_defaultContext]];
    presentationVisibilitySwitch = [[UISwitch alloc] init];
}

- (void)confirmDeletion {
    confirmDeletionAlertView = [[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:@"Are you sure you want to delete this presentation?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil];
    [confirmDeletionAlertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == confirmDeletionAlertView && [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]){
        [self delete];
    }
}

- (void)delete{
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(deletePresentation)]){
        [self.settingsDelegate deletePresentation];
    }
}

- (void)updatePresentation {
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(updatePresentation)]){
        [self.settingsDelegate updatePresentation];
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
    switch (indexPath.row) {
        case 0:
            [cell.imageView setImage:nil];
            [cell.textLabel setText:@"Private"];
            cell.accessoryView = presentationVisibilitySwitch;
            [presentationVisibilitySwitch setOn:[_presentation.visible boolValue]];
            [presentationVisibilitySwitch addTarget:self action:@selector(visiblitySwitched) forControlEvents:UIControlEventValueChanged];
            break;
        case 1:
            [cell.imageView setImage:[UIImage imageNamed:@"whiteTrash"]];
            [cell.textLabel setText:@"Delete Presentation"];
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (void)visiblitySwitched {
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0){
        [self confirmDeletion];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
