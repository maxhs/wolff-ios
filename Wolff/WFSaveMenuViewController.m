//
//  WFSaveMenuViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/3/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSaveMenuViewController.h"
#import "WFSaveMenuCell.h"
#import "Constants.h"
#import "WFUtilities.h"

@interface WFSaveMenuViewController () {
    UIImageView *navBarShadowView;
}

@end

@implementation WFSaveMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    self.tableView.rowHeight = 54.f;
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.07]];
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFSaveMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SaveMenuCell" forIndexPath:indexPath];
    [cell.textLabel setTextColor:(IDIOM == IPAD) ? [UIColor blackColor] : [UIColor whiteColor]];
     
    if (indexPath.row == 0){
        [cell.imageView setImage:IDIOM == IPAD ? [UIImage imageNamed:@"cloudUpload"] : [UIImage imageNamed:@"whiteCloudUpload"]];
        [cell.textLabel setText:@"Save"];
    } else {
        [cell.imageView setImage:IDIOM == IPAD ? [UIImage imageNamed:@"mobile"] : [UIImage imageNamed:@"whiteMobile"]];
        [cell.textLabel setText:@"Enable offline mode"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0){
        if (self.saveDelegate && [self.saveDelegate respondsToSelector:@selector(post)]){
            [self.saveDelegate post];
        }
    } else {
        if (self.saveDelegate && [self.saveDelegate respondsToSelector:@selector(enableOfflineMode)]){
            [self.saveDelegate enableOfflineMode];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
