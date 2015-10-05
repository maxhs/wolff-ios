//
//  SlideshowPhoto.h
//  Wolff
//
//  Created by Max Haines-Stiles on 10/5/15.
//  Copyright © 2015 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo, Slideshow;

@interface SlideshowPhoto : NSManagedObject

@property (nullable, nonatomic, retain) NSNumber *identifier;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) Slideshow *slideshow;
@property (nullable, nonatomic, retain) Photo *photo;

@end
