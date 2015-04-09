//
//  Slide.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo, Slideshow;

@interface Slide : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) Slideshow *slideshow;
@property (nonatomic, retain) NSOrderedSet *photoSlides;
@property (nonatomic, retain) NSOrderedSet *slideTexts;
@end
@interface Slide (CoreDataGeneratedAccessors)

@end
