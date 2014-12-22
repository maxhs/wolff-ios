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
#import "Location+helper.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface WFArtMetadataViewController () {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    NSDateFormatter *dateFormatter;
}

@end

@implementation WFArtMetadataViewController

@synthesize art = _art;

- (void)viewDidLoad
{
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    [self setupDateFormatter];
    [self setupHeader];
}

- (void)setupDateFormatter {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
}

- (void)setupHeader {
    self.tableView.tableHeaderView = _topImageContainerView;
    [_topImageView sd_setImageWithURL:[NSURL URLWithString:_art.photo.largeImageUrl] placeholderImage:[UIImage imageNamed:@"icon-180"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
    }];
    
    [_creditButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredLatoFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
    [_creditButton setTitle:_art.user.fullName forState:UIControlStateNormal];
    
    [_postedByButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredLatoFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
    [_postedByButton setTitle:_art.user.fullName forState:UIControlStateNormal];
    
    [_backButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    
    [_flagButton addTarget:self action:@selector(flag) forControlEvents:UIControlEventTouchUpInside];
    [_flagButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredLatoFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
    [_favoriteButton addTarget:self action:@selector(favorite) forControlEvents:UIControlEventTouchUpInside];
    [_favoriteButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredLatoFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadArtMetadata];
}

- (void)loadArtMetadata {
    [manager GET:[NSString stringWithFormat:@"arts/%@",_art.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success fetching metadata: %@",responseObject);
        [_art populateFromDictionary:[responseObject objectForKey:@"art"]];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching art metadata: %@",error.description);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFArtMetadataCell *cell = (WFArtMetadataCell *)[tableView dequeueReusableCellWithIdentifier:@"ArtMetadataCell"];
    
    switch (indexPath.row) {
        case 0:
            [cell.label setText:@"TITLE"];
            [cell.value setText:_art.title];
            break;
        case 1:
            [cell.label setText:@"ARTIST"];
            [cell.value setText:_art.primaryArtist.name];
            break;
        case 2:
            [cell.label setText:@"DATE"];
            if (_art.interval.single){
                [cell.value setText:[dateFormatter stringFromDate:_art.interval.single]];
            } else {
                
            }
            break;
        case 3:
            [cell.label setText:@"MEDIUM"];
            [cell.value setText:[_art mediaToSentence]];
            break;
        case 4:
            [cell.label setText:@"LOCATION"];
            [cell.value setText:[_art.locations.firstObject name]];
            break;
        case 5:
            [cell.label setText:@"INSTITUTION"];
            [cell.value setText:@"institution name"];
            break;
        case 6:
            [cell.label setText:@"LICENSE"];
            [cell.value setText:@"Public Domain"];
            break;
            
        default:
            break;
    }
    return cell;
}

- (void)favorite {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [manager POST:[NSString stringWithFormat:@"arts/%@/favorite",_art.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success posting favorite: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to favorite %@: %@",_art.title,error.description);
        }];
    } else {
        
    }
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

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
