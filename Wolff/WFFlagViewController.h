//
//  WFFlagViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/22/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Art+helper.h"
#import "Photo+helper.h"

@interface WFFlagViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (strong, nonatomic) Art *art;
@property (strong, nonatomic) Photo *photo;
@property (strong, nonatomic) User *currentUser;
@property BOOL copyright;
@property BOOL keyboardVisible;
@end
