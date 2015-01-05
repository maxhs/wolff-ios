//
//  WFImagePickerController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFImagePickerController.h"
#import "WFImagePickerCell.h"

@interface WFImagePickerController () {
    NSMutableArray *_assets;
    NSMutableOrderedSet *_selectedAssets;
    UIImageView *focusImageView;
    UIBarButtonItem *selectButton;
    BOOL selectMode;
}

@end

@implementation WFImagePickerController
static NSString * const reuseIdentifier = @"PhotoCell";

@synthesize assetsGroup = _assetsGroup;

- (void)viewDidLoad {
    [super viewDidLoad];
    _assets = [NSMutableArray array];
    _selectedAssets = [NSMutableOrderedSet orderedSet];
    [self loadPhotos];
    selectButton = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStylePlain target:self action:@selector(toggleSelectMode)];
    self.navigationItem.rightBarButtonItem = selectButton;
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
}

- (void)toggleSelectMode {
    selectMode ? (selectMode = NO) : (selectMode = YES);
}

- (void)loadPhotos {
    if([ALAssetsLibrary authorizationStatus]) {
        ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result) {
                [_assets addObject:result];
            }
        };
        
        ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
        [_assetsGroup setAssetsFilter:onlyPhotosFilter];
        [_assetsGroup enumerateAssetsUsingBlock:assetsEnumerationBlock];
        [self.collectionView reloadData];
    } else {
        NSLog(@"not authorized");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission Denied" message:@"Please allow the application to access your photo and videos in settings panel of your device" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _assets.count;
}

#define kImageViewTag 1 // the image view inside the collection view cell prototype is tagged with "1"

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    WFImagePickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    ALAsset *asset = _assets[indexPath.item];
    CGImageRef thumbnailImageRef = [asset thumbnail];
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
    [cell.imageView setImage:thumbnail];
    
    if ([_selectedAssets containsObject:asset]){
        [cell.checkmark setHidden:NO];
    } else {
        [cell.checkmark setHidden:YES];
    }
    
    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(128,128);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    ALAsset *asset = _assets[indexPath.item];
    WFImagePickerCell *selectedCell = (WFImagePickerCell*)[collectionView cellForItemAtIndexPath:indexPath];
    if (selectMode){
        if ([_selectedAssets containsObject:asset]){
            [_selectedAssets removeObject:asset];
        } else {
            [_selectedAssets addObject:asset];
        }
        NSString *viewTitle = _selectedAssets.count == 1 ? @"1 item selected" : [NSString stringWithFormat:@"%lu items selected",(unsigned long)_selectedAssets.count];
        self.title = viewTitle;
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
        if (focusImageView){
            [UIView animateWithDuration:.23f animations:^{
                [selectedCell.contentView setAlpha:1.f];
                focusImageView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                [focusImageView removeFromSuperview];
                focusImageView = nil;
            }];
        } else {
            [_selectedAssets addObject:asset];
            
            UIImage *fullImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]];
            focusImageView = [[UIImageView alloc] initWithImage:fullImage];
            
            [selectedCell.contentView setAlpha:0.1f];
            [self.view addSubview:focusImageView];
            
            [self.view bringSubviewToFront:focusImageView];
            NSLog(@"selected cell frame origin x: %f and y: %f",selectedCell.frame.origin.x,selectedCell.frame.origin.y);
            focusImageView.frame = selectedCell.frame;
            
            [UIView animateWithDuration:.23f animations:^{
                CGAffineTransform transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                focusImageView.transform = transform;
            }];
        }
    }
}

#pragma mark - Segue support

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showPhoto"]) {
        
        // hand off the assets of this album to our singleton data source
        //[PageViewControllerData sharedInstance].photoAssets = self.assets;
        
        // start viewing the image at the appropriate cell index
        //MyPageViewController *pageViewController = [segue destinationViewController];
        //NSIndexPath *selectedCell = [self.collectionView indexPathsForSelectedItems][0];
        //pageViewController.startingIndex = selectedCell.row;
    }
}

- (void)cancel {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 // Uncomment this method to specify if the specified item should be highlighted during tracking
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
 }
 */

/*
 // Uncomment this method to specify if the specified item should be selected
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
 return YES;
 }
 */

/*
 // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
 }
 
 - (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
 }
 
 - (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
 }
 */

@end