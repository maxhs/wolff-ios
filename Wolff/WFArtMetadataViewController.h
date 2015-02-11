//
//  WFArtMetadataViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Art+helper.h"
#import "Table+helper.h"

@protocol WFMetadataDelegate <NSObject>
@optional
- (void)artFlagged:(Art*)art;
- (void)photoFlagged:(Photo*)photo;
- (void)favoritedPhoto:(Photo*)photo;
- (void)droppedPhoto:(Photo*)photo toLightTable:(Table*)lightTable;
- (void)removedPhoto:(Photo*)photo fromLightTable:(Table*)lightTable;
- (void)photoDeleted:(NSNumber*)photoId;
@end

@interface WFArtMetadataViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topImageContainerView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressIndicator;
@property (weak, nonatomic) IBOutlet UIButton *creditButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *dropToTableButton;
@property (weak, nonatomic) IBOutlet UIButton *flagButton;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UIButton *nextPhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *lastPhotoButton;
@property (weak, nonatomic) IBOutlet UILabel *photoCountLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *photoScrollView;
@property (strong, nonatomic) Photo *photo;
@property (weak, nonatomic) id<WFMetadataDelegate> metadataDelegate;

- (void)dismiss;

@end
