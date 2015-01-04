//
//  Photo.h
//  Wolff
//
//  Created by Max Haines-Stiles on 10/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Art;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * visible;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * orientation;
@property (nonatomic, retain) NSString * largeImageUrl;
@property (nonatomic, retain) NSString * thumbImageUrl;
@property (nonatomic, retain) NSString * slideImageUrl;
@property (nonatomic, retain) NSString * mediumImageUrl;
@property (nonatomic, retain) NSString * originalImageUrl;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) Art *art;

@end
