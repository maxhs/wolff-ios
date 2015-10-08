//
//  WFImagePickerController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFImagePickerController.h"
#import "WFImagePickerCell.h"
#import "Constants.h"
#import "WFUtilities.h"
#import "ProgressHUD.h"
#import <MagicalRecord/MagicalRecord.h>
#import "Photo+helper.h"

@interface WFImagePickerController () {
    CGFloat width;
    CGFloat height;
    NSMutableArray *_assets;
    NSMutableOrderedSet *_selectedAssets;
    UIImageView *focusImageView;
    UIImageView *navBarShadowView;
    UIBarButtonItem *selectButton;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *backButton;
    BOOL selectMode;
    CGSize thumbnailSize;
}

@end

@implementation WFImagePickerController
static NSString * const reuseIdentifier = @"PhotoCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    [self.collectionView setContentInset:UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height, 0, 0, 0)];
    [_collectionView setBackgroundColor:[UIColor clearColor]];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [backgroundToolbar setTranslucent:YES];
    [_collectionView setBackgroundView:backgroundToolbar];
    width = screenWidth();
    height = screenHeight();
    
    thumbnailSize = IDIOM == IPAD ? CGSizeMake(width/10,width/10) : CGSizeMake(width/4, width/4);
    
    _assets = [NSMutableArray array];
    _selectedAssets = [NSMutableOrderedSet orderedSet];
    [self loadPhotos];
    selectButton = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStylePlain target:self action:@selector(toggleSelectMode)];

    selectMode = YES;
    
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dismissWhite"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStylePlain target:self action:@selector(done)];
    doneButton.enabled = NO;
    
    self.navigationItem.rightBarButtonItem = doneButton;
    self.navigationItem.leftBarButtonItem = backButton;
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    backButton = self.navigationItem.backBarButtonItem;
    navBarShadowView.hidden = YES;
}

- (void)toggleSelectMode {
    selectMode ? (selectMode = NO) : (selectMode = YES);
    self.navigationItem.rightBarButtonItem = selectMode ? doneButton : selectButton;
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)loadPhotos {
    PHFetchOptions *allPhotosOptions = [PHFetchOptions new];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *allPhotosResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:allPhotosOptions];
    [allPhotosResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        [_assets addObject:asset];
    }];
    if (_assets.count){
        [self.collectionView reloadData];
        NSInteger lastItem = [self.collectionView numberOfItemsInSection:0];
        NSIndexPath *lastItemIndexPath = [NSIndexPath indexPathForItem:lastItem-1 inSection:0];
        [self.collectionView scrollToItemAtIndexPath:lastItemIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFImagePickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    PHAsset *asset = _assets[indexPath.item];
    PHImageRequestOptions *initialRequestOptions = [[PHImageRequestOptions alloc] init];
    initialRequestOptions.synchronous = NO;
    initialRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    initialRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(thumbnailSize.width*2, thumbnailSize.width*2) contentMode:PHImageContentModeAspectFill options:initialRequestOptions resultHandler:^(UIImage * image, NSDictionary * info) {
        if (image){
            cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
            [cell.imageView setImage:image];
        }
    }];
    
    [cell.checkmark setHidden:[_selectedAssets containsObject:asset] ? NO : YES];

    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return thumbnailSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = _assets[indexPath.item];
    WFImagePickerCell *selectedCell = (WFImagePickerCell*)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (selectMode){
        if ([_selectedAssets containsObject:asset]){
            [_selectedAssets removeObject:asset];
        } else {
            [_selectedAssets addObject:asset];
        }
        NSString *viewTitle = _selectedAssets.count == 1 ? @"1 image selected" : [NSString stringWithFormat:@"%lu images selected",(unsigned long)_selectedAssets.count];
        self.title = viewTitle;
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {

        [_selectedAssets addObject:asset];
        [selectedCell.contentView setAlpha:0.23f];
        [self.view addSubview:focusImageView];
        [self.view bringSubviewToFront:focusImageView];
        focusImageView.frame = selectedCell.frame;
        CGRect newFrame = CGRectMake(width/2-400, height/2-300, 800, 600);
        
        [UIView animateWithDuration:.23f animations:^{
            [focusImageView setFrame:newFrame];
        }];
    }
    doneButton.enabled = _selectedAssets.count;
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)done {
    if (_selectedAssets.count && self.delegate && [self.delegate respondsToSelector:@selector(didFinishPickingPhotos:)]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [ProgressHUD show:_selectedAssets.count == 1 ? @"Fetching image..." : @"Fetching images..."];
        });
        
        NSMutableArray *photoArray = [NSMutableArray arrayWithCapacity:_selectedAssets.count];
        PHImageManager *defaultManager = [PHImageManager defaultManager];
        PHImageRequestOptions *initialRequestOptions = [[PHImageRequestOptions alloc] init];
        initialRequestOptions.synchronous = YES;
        initialRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
        initialRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        [_selectedAssets enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            @autoreleasepool {
                [defaultManager requestImageForAsset:asset targetSize:CGSizeMake(width, width) contentMode:PHImageContentModeAspectFill options:initialRequestOptions resultHandler:^(UIImage * image, NSDictionary * info) {
                    if (image){
                        Photo *photo = [Photo MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
                        [photo setImage:image];
                        NSArray *resources = [PHAssetResource assetResourcesForAsset:asset];
                        [photo setFileName:((PHAssetResource*)resources[0]).originalFilename];
                        [photo setAssetUrl:((PHAssetResource*)resources[0]).assetLocalIdentifier];
                       [photoArray addObject:photo];
                    }
                }];
            }
        }];
        if (photoArray.count){
            [self.delegate didFinishPickingPhotos:photoArray];
        } else {
            [self dismiss];
        }
    } else {
        [self dismiss];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
