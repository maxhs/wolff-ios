//
//  LightTable.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface LightTable : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * visible;
@property (nonatomic, retain) NSNumber * privateTable;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * tableDescription;
@property (nonatomic, retain) NSString * code;
@property (nonatomic, retain) NSOrderedSet *discussions;
@property (nonatomic, retain) NSOrderedSet *slideshows;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) NSOrderedSet *users;
@property (nonatomic, retain) NSOrderedSet *owners;
@end

@interface LightTable (CoreDataGeneratedAccessors)

@end
