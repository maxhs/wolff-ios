//
//  Group.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Art, User;

@interface Group : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSOrderedSet *arts;
@property (nonatomic, retain) User *users;
@end

@interface Group (CoreDataGeneratedAccessors)

- (void)insertObject:(Art *)value inArtsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromArtsAtIndex:(NSUInteger)idx;
- (void)insertArts:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeArtsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInArtsAtIndex:(NSUInteger)idx withObject:(Art *)value;
- (void)replaceArtsAtIndexes:(NSIndexSet *)indexes withArts:(NSArray *)values;
- (void)addArtsObject:(Art *)value;
- (void)removeArtsObject:(Art *)value;
- (void)addArts:(NSOrderedSet *)values;
- (void)removeArts:(NSOrderedSet *)values;
@end
