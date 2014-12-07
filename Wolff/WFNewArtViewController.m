//
//  WFNewArtViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/23/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFNewArtViewController.h"
#import "WFAppDelegate.h"
#import "WFNewArtCell.h"
#import "WFNewArtPhotoCell.h"
@interface WFNewArtViewController () <UITableViewDataSource, UITableViewDelegate , UIScrollViewDelegate, UIImagePickerControllerDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
}

@end

@implementation WFNewArtViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self setupTableFooter];
}

- (void)setupTableFooter {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return 1;
            break;
            
        default:
            return 0;
            break;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0){
        WFNewArtPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewArtPhotoCell"];
        [cell.uploadButton addTarget:self action:@selector(showPhotoLibrary) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    } else {
        WFNewArtCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewArtCell"];
        switch (indexPath.row) {
            case 0:
                [cell.textField setPlaceholder:@"Piece title"];
                break;
                
            default:
                break;
        }
        return cell;
    }
}

- (void)showPhotoLibrary {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
