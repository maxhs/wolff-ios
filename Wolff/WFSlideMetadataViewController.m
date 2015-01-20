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
    BOOL iOS8;
}

@end

@implementation WFSlideMetadataViewController
@synthesize photos = _photos;
@synthesize slide = _slide;
@synthesize slideshow = _slideshow;

- (void)viewDidLoad {
    [super viewDidLoad];
    iOS8 = SYSTEM_VERSION >= 8.f ? YES : NO;
    
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"right"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.02]];
    self.navigationItem.title = _slideshow.title;
    [self setupDateFormatter];
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.tableView.frame];
    [backgroundToolbar setTranslucent:YES];
    [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [self.tableView setBackgroundView:backgroundToolbar];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.view setBackgroundColor:[UIColor clearColor]];
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    self.tableView.tableFooterView = [UIView new];
    NSMutableSet *artSet = [NSMutableSet set];
    if (_slide.photos.count){
        for (Photo *photo in _slide.photos){
            [artSet addObject:photo.art];
        }
    } else {
        for (Photo *photo in _photos){
            [artSet addObject:photo.art];
        }
    }
    for (Art *art in artSet){
        [self loadMetadata:art];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)loadMetadata:(Art*)art{
    [manager GET:[NSString stringWithFormat:@"arts/%@",art.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success loading art: %@",responseObject);
        [art populateFromDictionary:[responseObject objectForKey:@"art"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self.tableView reloadData];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load art: %@",error.description);
    }];
}

- (void)setupDateFormatter {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self multipleImages]){
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
    if (!iOS8){
        [cell awakeFromNib];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    NSArray *photosArray = _photos.count ? _photos.array : _slide.photos.array;
    Photo *photo;
    if (photosArray.count > 1){
        photo = indexPath.section == 0 ? photosArray.firstObject : photosArray[1];
    } else {
        photo = photosArray.firstObject;
    }
    Art *art = photo.art;
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    [cell.textLabel setNumberOfLines:0];
    
    switch (indexPath.row) {
        case 0:
            [cell.textLabel setText:art.title];
            [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0]];
            break;
        case 1:
        {
            NSString *artists = [photo.art artistsToSentence];
            if (artists.length > 1){
                [cell.textLabel setText:artists];
            } else {
                [cell.textLabel setText:@"Artist(s) Unknown"];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansThinItalic] size:0]];
                [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
            break;
        case 2:
        {
            if (art.interval.single){
                //check exact date
                [cell.textLabel setText:[dateFormatter stringFromDate:art.interval.single]];
            } else if (art.interval.beginRange && ![art.interval.beginRange isEqualToNumber:@0] && art.interval.endRange && ![art.interval.endRange isEqualToNumber:@0]) {
                //check for range
                NSString *beginSuffix = art.interval.beginSuffix.length ? art.interval.beginSuffix : @"CE";
                NSString *endSuffix = art.interval.endSuffix.length ? art.interval.endSuffix : @"CE";
                [cell.textLabel setText:[NSString stringWithFormat:@"%@ %@ - %@ %@",art.interval.beginRange, beginSuffix, art.interval.endRange, endSuffix]];
            } else if (art.interval.year && ![art.interval.year isEqualToNumber:@0]){
                NSString *suffix = art.interval.suffix.length ? art.interval.suffix : @"CE";
                [cell.textLabel setText:[NSString stringWithFormat:@"%@ %@",art.interval.year, suffix]];
            } else {
                [cell.textLabel setText:@"No date listed"];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansThinItalic] size:0]];
                [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            }
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
                [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
            break;
        case 4:
        {
            NSString *locations = [art locationsToSentence];
            if (locations.length){
                [cell.textLabel setText:locations];
            } else {
                [cell.textLabel setText:@"No locations listed"];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansThinItalic] size:0]];
                [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
            break;
        default:
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self multipleImages]){
        if (section == 0){
            return 34;
        } else {
            return 100;
        }
    } else {
        return 0;
    }
}

- (BOOL)multipleImages {
    if (_photos.count > 1 || _slide.photos.count > 1){
        return YES;
    } else {
        return NO;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    CGFloat headerHeight;
    if ([self multipleImages]){
        if (section == 0){
            headerHeight = 34;
        } else {
            headerHeight = 100;
        }
    } else {
        headerHeight = 0;
    }
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, headerHeight)];
    if ([self multipleImages]){
        CGFloat yOffset = section == 0 ? 0 : 66;
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, tableView.frame.size.width, 34)];
        [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
        [headerLabel setTextColor:[UIColor colorWithWhite:1 alpha:.43]];
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
