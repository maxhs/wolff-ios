//
//  WFSaveMenuViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/3/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol WFSaveSlideshowDelegate <NSObject>

- (void)post;

@end

@interface WFSaveMenuViewController : UITableViewController
@property (weak, nonatomic) id<WFSaveSlideshowDelegate>saveDelegate;
@end
