//
//  Folder.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Art, Presentation;

@interface Folder : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet *arts;
@property (nonatomic, retain) NSOrderedSet *presentations;
@end

@interface Folder (CoreDataGeneratedAccessors)

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
- (void)insertObject:(Presentation *)value inPresentationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPresentationsAtIndex:(NSUInteger)idx;
- (void)insertPresentations:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePresentationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPresentationsAtIndex:(NSUInteger)idx withObject:(Presentation *)value;
- (void)replacePresentationsAtIndexes:(NSIndexSet *)indexes withPresentations:(NSArray *)values;
- (void)addPresentationsObject:(Presentation *)value;
- (void)removePresentationsObject:(Presentation *)value;
- (void)addPresentations:(NSOrderedSet *)values;
- (void)removePresentations:(NSOrderedSet *)values;
@end
