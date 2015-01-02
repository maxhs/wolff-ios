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
#import "Art+helper.h"
#import "WFAssetGroupPickerController.h"
#import "WFImagePickerController.h"

@interface WFNewArtViewController () <UITableViewDataSource, UITableViewDelegate , UIScrollViewDelegate, WFImagePickerControllerDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UITextField *titleTextField;
    Art *_art;
}

@end

@implementation WFNewArtViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self setupTableFooter];
    [self setupSlideContainer];
    _art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [titleTextField becomeFirstResponder];
}

- (void)setupSlideContainer {
    [_slideContainerView setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
    _slideContainerView.layer.cornerRadius = 14.f;
    
    _slideContainerView.layer.backgroundColor = [UIColor colorWithWhite:.95 alpha:1].CGColor;
    _slideContainerView.layer.shadowColor = [UIColor colorWithWhite:.5 alpha:1].CGColor;
    _slideContainerView.layer.shadowOpacity = .4f;
    _slideContainerView.layer.shadowOffset = CGSizeMake(1.3f, 1.7f);
    _slideContainerView.layer.shadowRadius = 1.3f;
    
    _slideContainerView.clipsToBounds = NO;
    
    [_addPhotoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [_addPhotoButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [_addPhotoButton addTarget:self action:@selector(showPhotoOptions) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showPhotoOptions {
    //UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"SELECT A PHOTO" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Choose Photo",@"Take Photo", nil];
    [self choosePhoto];
}

- (void)choosePhoto {
    WFAssetGroupPickerController *imagePicker = [[self storyboard] instantiateViewControllerWithIdentifier:@"AssetGroupPicker"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imagePicker];
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)didFinishPickingPhotos:(NSMutableArray *)selectedPhotos {
    [self dismissViewControllerAnimated:YES completion:NULL];
    //[_addPhotoButton setImage:image forState:UIControlStateNormal];
    Photo *photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    //[photo setImage:image];
    [_art addPhoto:photo];
    //[self.tableView reloadData];
}

- (void)setupTableFooter {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFNewArtCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewArtCell"];
    [cell.textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    switch (indexPath.row) {
        case 0:
            [cell.label setText:@"TITLE"];
            [cell.textField setPlaceholder:@"Art title"];
            titleTextField = cell.textField;
            break;
        case 1:
            [cell.label setText:@"ARTIST"];
            [cell.textField setPlaceholder:@"Artist"];
            break;
        case 2:
            [cell.label setText:@"DATE"];
            [cell.textField setPlaceholder:@"Date"];
            break;
        case 3:
            [cell.label setText:@"LOCATION"];
            [cell.textField setPlaceholder:@"Location"];
            break;
            
        default:
            break;
    }
    return cell;
}

- (void)showPhotoLibrary {
    
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
