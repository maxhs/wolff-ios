//
//  Slideshow+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Slideshow.h"
#import "Photo+helper.h"
#import "Slide+helper.h"

@interface Slideshow (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (void)addSlide:(Slide*)slide;
- (void)removeSlide:(Slide*)slide;
- (void)addPhoto:(Photo*)photo;
- (void)removePhoto:(Photo*)photo;

@end