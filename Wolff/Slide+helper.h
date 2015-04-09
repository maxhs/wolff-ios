//
//  Slide+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Slide.h"
#import "Art+helper.h"
#import "PhotoSlide+helper.h"

@interface Slide (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (void)addPhotoSlide:(PhotoSlide*)photoSlide;
- (void)removePhotoSlide:(PhotoSlide*)photoSlide;
- (void)replacePhotoSlideAtIndex:(NSInteger)index withPhotoSlide:(PhotoSlide*)photoSlide;
- (NSOrderedSet*)photos;
@end
