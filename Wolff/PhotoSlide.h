//
//  PhotoSlide.h
//  Wolff
//
//  Created by Max Haines-Stiles on 3/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Slide, Photo;

@interface PhotoSlide : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * scale;
@property (nonatomic, retain) NSNumber * positionX;
@property (nonatomic, retain) NSNumber * positionY;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) Slide *slide;
@property (nonatomic, retain) Photo *photo;

@end
