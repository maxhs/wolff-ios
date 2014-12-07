//
//  Favorite.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/23/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Art, User;

@interface Favorite : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Art *art;
@property (nonatomic, retain) NSManagedObject *artist;

@end
