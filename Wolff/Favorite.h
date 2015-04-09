//
//  Favorite.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/23/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Art, Artist, User, Photo, LightTable;

@interface Favorite : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Art *art;
@property (nonatomic, retain) Photo *photo;
@property (nonatomic, retain) Artist *artist;
@property (nonatomic, retain) LightTable *table;

@end
