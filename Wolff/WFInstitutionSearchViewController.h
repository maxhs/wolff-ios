//
//  WFInstitutionSearchViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Institution+helper.h"

@protocol WFInstitutionSearchDelegate <NSObject>
- (void)institutionSelected:(Institution*)institution;
@end

@interface WFInstitutionSearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) id<WFInstitutionSearchDelegate>searchDelegate;

@end
