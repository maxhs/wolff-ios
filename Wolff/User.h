//
//  User.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface User : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * mobileToken;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * admin;
@property (nonatomic, retain) NSNumber * emailPermission;
@property (nonatomic, retain) NSNumber * textPermission;
@property (nonatomic, retain) NSNumber * pushPermission;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * customerPlan;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * prefix;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * bio;
@property (nonatomic, retain) NSString * avatarSmall;
@property (nonatomic, retain) NSString * avatarLarge;
@property (nonatomic, retain) NSOrderedSet *institutions;
@property (nonatomic, retain) NSOrderedSet *lightTables;
@property (nonatomic, retain) NSOrderedSet *ownedTables;
@property (nonatomic, retain) NSOrderedSet *arts;
@property (nonatomic, retain) NSOrderedSet *favorites;
@property (nonatomic, retain) NSOrderedSet *slideshows;
@property (nonatomic, retain) NSOrderedSet *comments;
@property (nonatomic, retain) NSOrderedSet *notifications;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) NSOrderedSet *alternates;
@property (nonatomic, retain) NSOrderedSet *cards;
@property (nonatomic, retain) NSOrderedSet *notes;

@end

@interface User (CoreDataGeneratedAccessors)

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
