//
//  WFMaterialsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/6/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Material+helper.h"
@protocol WFSelectMaterialsDelegate <NSObject>
- (void)materialsSelected:(NSOrderedSet*)selectedMaterials;
@end

@interface WFMaterialsViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *noSearchResultsLabel;
@property (strong, nonatomic) NSMutableOrderedSet *selectedMaterials;
@property (weak, nonatomic) id<WFSelectMaterialsDelegate>materialDelegate;
@end
