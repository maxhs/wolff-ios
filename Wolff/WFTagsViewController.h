//
//  WFTagsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 4/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tag+helper.h"

@protocol WFSelectTagsDelegate <NSObject>
- (void)tagsSelected:(NSOrderedSet*)selectedTags;
@end

@interface WFTagsViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate>
@property (strong, nonatomic) Art *art;
@property BOOL communityTagMode;
@property (strong, nonatomic) NSMutableOrderedSet *selectedTags;
@property (weak, nonatomic) id<WFSelectTagsDelegate>tagDelegate;
@end
