//
//  Tag.h
//  Wolff
//
//  Created by Max Haines-Stiles on 4/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Art, Photo;

@interface Tag : NSManagedObject
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet *arts;
@end

@interface Tag (CoreDataGeneratedAccessors)

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
- (void)insertObject:(Photo *)value inPhotosAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx;
- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePhotosAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(Photo *)value;
- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values;
- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSOrderedSet *)values;
- (void)removePhotos:(NSOrderedSet *)values;
@end
