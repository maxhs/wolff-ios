//
//  WFSlideMetadataViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/3/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSlideMetadataViewController.h"
#import "WFAppDelegate.h"
#import "WFArtMetadataCell.h"
#import "WFSlideMetadataCell.h"
#import "WFUtilities.h"

@interface WFSlideMetadataViewController () <UITableViewDataSource, UITableViewDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UIBarButtonItem *dismissButton;
    NSDateFormatter *dateFormatter;
    UIImageView *navBarShadowView;
}

@end

@implementation WFSlideMetadataViewController
@synthesize arts = _arts;
@synthesize slide = _slide;
@synthesize presentation = _presentation;

- (void)viewDidLoad {
    [super viewDidLoad];
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"right"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.01]];
    self.navigationItem.title = _presentation.title;
    [self setupDateFormatter];
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.tableView.frame];
    [backgroundToolbar setTranslucent:YES];
    [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [self.tableView setBackgroundView:backgroundToolbar];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.view setBackgroundColor:[UIColor clearColor]];
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)setupDateFormatter {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_arts.count || _slide.arts.count > 1){
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFSlideMetadataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SlideMetadataCell" forIndexPath:indexPath];
    NSArray *artsArray = _arts.count ? _arts.array : _slide.arts.array;
    Art *art;
    if (artsArray.count > 1){
        if (indexPath.section == 0){
            art = artsArray.firstObject;
        } else {
            art = artsArray[1];
        }
    } else {
        art = artsArray.firstObject;
    }
    
    switch (indexPath.row) {
        case 0:
            [cell.textLabel setText:art.title];
            [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0]];
            break;
        case 1:
        {
            NSString *artists = [art artistsToSentence];
            if (artists.length > 1){
                [cell.textLabel setText:artists];
            } else {
                [cell.textLabel setText:@"Artist(s) unknown..."];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansThinItalic] size:0]];
            }
        }
            break;
        case 2:
            if (art.interval.single){
                [cell.textLabel setText:[dateFormatter stringFromDate:art.interval.single]];
            } else if (![art.interval.beginRange isEqualToNumber:@0] && ![art.interval.endRange isEqualToNumber:@0]) {
                NSString *beginSuffix = art.interval.beginSuffix.length ? art.interval.beginSuffix : @"CE";
                NSString *endSuffix = art.interval.endSuffix.length ? art.interval.endSuffix : @"CE";
                [cell.textLabel setText:[NSString stringWithFormat:@"%@ %@ - %@ %@",art.interval.beginRange, beginSuffix, art.interval.endRange, endSuffix]];
            } else if (![art.interval.year isEqualToNumber:@0]){
                NSString *suffix = art.interval.suffix.length ? art.interval.suffix : @"CE";
                [cell.textLabel setText:[NSString stringWithFormat:@"%@ %@",art.interval.year, suffix]];
            } else {
                [cell.textLabel setText:@"No date listed"];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansThinItalic] size:0]];
                
            }
            break;
        case 3:
        {
            NSString *materials = [art materialsToSentence];
            if (materials.length){
                [cell.textLabel setText:materials];
            } else {
                [cell.textLabel setText:@"No materials listed"];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansThinItalic] size:0]];
            }
        }
        case 4:
        {
            NSString *locations = [art locationsToSentence];
            if (locations.length){
                [cell.textLabel setText:locations];
            } else {
                [cell.textLabel setText:@"No locations listed"];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        default:
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (_arts.count || _slide.arts.count > 1){
        if (section == 0){
            return 34;
        } else {
            return 100;
        }
    } else {
        return 0;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    CGFloat headerHeight;
    if (_arts.count || _slide.arts.count > 1){
        if (section == 0){
            headerHeight = 34;
        } else {
            headerHeight = 100;
        }
    } else {
        headerHeight = 0;
    }
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, headerHeight)];
    if (_arts.count || _slide.arts.count > 1){
        CGFloat yOffset = section == 0 ? 0 : 66;
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, tableView.frame.size.width, 34)];
        [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansThin] size:0]];
        [headerLabel setTextColor:[UIColor colorWithWhite:1 alpha:.23]];
        [headerLabel setTextAlignment:NSTextAlignmentCenter];
        if (section == 0){
            [headerLabel setText:@"LEFT"];
        } else {
            [headerLabel setText:@"RIGHT"];
        }
        [headerView addSubview:headerLabel];
    }
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
