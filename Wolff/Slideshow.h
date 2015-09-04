//
//  Slideshow.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Slideshow : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * visible;
@property (nonatomic, retain) NSNumber * showTitleSlide;
@property (nonatomic, retain) NSNumber * showMetadata;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * slideshowDescription;
@property (nonatomic, retain) NSOrderedSet *slides;
@property (nonatomic, retain) NSOrderedSet *discussions;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) NSOrderedSet *lightTables;
@property (nonatomic, retain) User * owner;
@end

@interface Slideshow (CoreDataGeneratedAccessors)

- (void)insertObject:(NSManagedObject *)value inSlidesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSlidesAtIndex:(NSUInteger)idx;
- (void)insertSlides:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSlidesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSlidesAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceSlidesAtIndexes:(NSIndexSet *)indexes withSlides:(NSArray *)values;
- (void)addSlidesObject:(NSManagedObject *)value;
- (void)removeSlidesObject:(NSManagedObject *)value;
- (void)addSlides:(NSOrderedSet *)values;
- (void)removeSlides:(NSOrderedSet *)values;
@end
