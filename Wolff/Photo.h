//
//  Photo.h
//  Wolff
//
//  Created by Max Haines-Stiles on 10/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@class Art, User;
@interface Photo : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * privatePhoto;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * orientation;
@property (nonatomic, retain) NSNumber * flagged;
@property (nonatomic, retain) NSNumber * primary;
@property (nonatomic, retain) NSNumber * orderIndex;
@property (nonatomic, retain) NSString * largeImageUrl;
@property (nonatomic, retain) NSString * thumbImageUrl;
@property (nonatomic, retain) NSString * mediumImageUrl;
@property (nonatomic, retain) NSString * slideImageUrl;
@property (nonatomic, retain) NSString * originalImageUrl;
@property (nonatomic, retain) NSString * credit;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSString * fileName;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSOrderedSet *slides;
@property (nonatomic, retain) NSOrderedSet *photoSlides;
@property (nonatomic, retain) NSOrderedSet *icons;
@property (nonatomic, retain) NSOrderedSet *tables;
@property (nonatomic, retain) NSOrderedSet *artists;
@property (nonatomic, retain) NSOrderedSet *notifications;
@property (nonatomic, retain) NSOrderedSet *partners;
@property (nonatomic, retain) Art *art;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) id image;

@end
