//
//  Card.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/20/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Card : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * brand;
@property (nonatomic, retain) NSString * expMonth;
@property (nonatomic, retain) NSString * expYear;
@property (nonatomic, retain) NSString * zip;
@property (nonatomic, retain) NSString * last4;
@property (nonatomic, retain) NSDate *createdDate;
@property (nonatomic, retain) User *user;

@end
