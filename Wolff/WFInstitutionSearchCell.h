//
//  WFInstitutionSearchCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Institution+helper.h"

@interface WFInstitutionSearchCell : UITableViewCell

- (void)configureForInstitution:(Institution*)institution;

@end
