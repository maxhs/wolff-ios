//
//  Comment.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Discussion, User;

@interface Comment : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) Discussion *discussion;
@property (nonatomic, retain) User *user;

@end
