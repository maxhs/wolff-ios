//
//  Art.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Art : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * thumbImageUrl;
@property (nonatomic, retain) NSString * smallImageUrl;
@property (nonatomic, retain) NSString * mediumImageUrl;
@property (nonatomic, retain) NSString * largeImageUrl;
@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSString * iconography;
@property (nonatomic, retain) NSManagedObject *artist;
@property (nonatomic, retain) NSOrderedSet *groups;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) User *user;
@end

@interface Art (CoreDataGeneratedAccessors)

- (void)insertObject:(NSManagedObject *)value inGroupsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromGroupsAtIndex:(NSUInteger)idx;
- (void)insertGroups:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeGroupsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInGroupsAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceGroupsAtIndexes:(NSIndexSet *)indexes withGroups:(NSArray *)values;
- (void)addGroupsObject:(NSManagedObject *)value;
- (void)removeGroupsObject:(NSManagedObject *)value;
- (void)addGroups:(NSOrderedSet *)values;
- (void)removeGroups:(NSOrderedSet *)values;
@end
