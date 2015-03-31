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
@property (nonatomic, retain) NSString * originalRectString1;
@property (nonatomic, retain) NSString * originalRectString2;
@property (nonatomic, retain) NSString * originalRectString3;
@property (nonatomic, retain) NSString * rectString1;
@property (nonatomic, retain) NSString * rectString2;
@property (nonatomic, retain) NSString * rectString3;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) Slideshow *slideshow;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) NSOrderedSet *slidePhotos;
@property (nonatomic, retain) NSOrderedSet *slideTexts;
@end
@interface Slide (CoreDataGeneratedAccessors)

@end
