//
//  Table.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo, User;

@interface Table : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * visible;
@property (nonatomic, retain) NSNumber * privateTable;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * tableDescription;
@property (nonatomic, retain) NSOrderedSet *discussions;
@property (nonatomic, retain) NSOrderedSet *slideshows;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) User *users;
@end

@interface Table (CoreDataGeneratedAccessors)

@end
