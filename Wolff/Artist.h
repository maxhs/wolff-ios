//
//  Artist.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Art, Favorite;

@interface Artist : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * birthYear;
@property (nonatomic, retain) NSNumber * deathYear;
@property (nonatomic, retain) NSDate * birthDate;
@property (nonatomic, retain) NSDate * deathDate;
@property (nonatomic, retain) NSOrderedSet *arts;
@property (nonatomic, retain) NSOrderedSet *favorites;
@property (nonatomic, retain) NSOrderedSet *discussions;
@property (nonatomic, retain) NSOrderedSet *notifications;
@property (nonatomic, retain) NSOrderedSet *photos;

@end

@interface Artist (CoreDataGeneratedAccessors)

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
- (void)insertObject:(Favorite *)value inFavoritesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromFavoritesAtIndex:(NSUInteger)idx;
- (void)insertFavorites:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeFavoritesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInFavoritesAtIndex:(NSUInteger)idx withObject:(Favorite *)value;
- (void)replaceFavoritesAtIndexes:(NSIndexSet *)indexes withFavorites:(NSArray *)values;
- (void)addFavoritesObject:(Favorite *)value;
- (void)removeFavoritesObject:(Favorite *)value;
- (void)addFavorites:(NSOrderedSet *)values;
- (void)removeFavorites:(NSOrderedSet *)values;
@end
