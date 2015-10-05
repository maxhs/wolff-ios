//
//  WFImagePickerController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@protocol WFImagePickerControllerDelegate <NSObject>

@required
- (void)didFinishPickingPhotos:(NSMutableArray*)selectedPhotos;
@end

@interface WFImagePickerController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) id<WFImagePickerControllerDelegate> delegate;

@end
