//
//  WFArtMetadataViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFArtMetadataViewController.h"
#import "WFArtMetadataCell.h"
#import "WFMainViewController.h"
#import "WFArtsViewController.h"

@interface WFArtMetadataViewController () {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UITapGestureRecognizer *dismissGesture;
}

@end

@implementation WFArtMetadataViewController

@synthesize art = _art;

- (void)viewDidLoad
{
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    dismissGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    dismissGesture.numberOfTapsRequired = 1;
    [self.presentingViewController.view addGestureRecognizer:dismissGesture];
    
    [self setupHeader];
}

- (void)setupHeader {
    self.tableView.tableHeaderView = _topImageContainerView;
    [_topImageView setImage:[UIImage imageNamed:@"art.jpg"]];
    
    [_creditButton.titleLabel setFont:[UIFont fontWithName:kMyriadLight size:20]];
    [_postedByButton.titleLabel setFont:[UIFont fontWithName:kMyriadLight size:20]];
    [_backButton addTarget:self action:@selector(tapDismiss) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)dismiss {
    self.presentingViewController.view.gestureRecognizers = nil;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        dismissGesture = nil;
    }];
}

- (void)loadArtMetadata {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [manager GET:[NSString stringWithFormat:@"%@/arts",_art.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success fetching metadata: %@",responseObject);
        [_art populateFromDictionary:[responseObject objectForKey:@"art.jpg"]];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching art metadata: %@",error.description);
    }];
}

- (void)tapDismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WFArtMetadataCell *cell = (WFArtMetadataCell *)[tableView dequeueReusableCellWithIdentifier:@"ArtMetadataCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"WFArtMetadataCell" owner:nil options:nil] lastObject];
    }
    [cell.textLabel setText:[NSString stringWithFormat:@"Metadata: %ld",(long)indexPath.row]];
    switch (indexPath.row) {
        case 0:
            
            break;
        case 1:
            
            break;
        case 2:
            
            break;
            
        default:
            break;
    }
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
