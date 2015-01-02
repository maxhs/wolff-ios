//
//  WFPresentationsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Presentation+helper.h"

@protocol WFPresentationDelegate <NSObject>

@required
- (void)newPresentation;
- (void)presentationSelected:(Presentation*)presentation;
@end

@interface WFPresentationsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) id<WFPresentationDelegate> presentationDelegate;

@end
