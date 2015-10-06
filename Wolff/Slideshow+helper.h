//
//  Slideshow+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Slideshow.h"
#import "SlideshowPhoto+helper.h"
#import "Slide+helper.h"

@interface Slideshow (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;

- (void)addSlide:(Slide*)slide atIndex:(NSInteger)index;
- (void)removeSlide:(Slide*)slide fromIndex:(NSInteger)index;
- (void)addSlideshowPhoto:(SlideshowPhoto*)slideshowPhoto;
- (void)removeSlideshowPhoto:(SlideshowPhoto*)slideshowPhoto;
- (void)orderPhotos;
- (BOOL)isOwnedByUser:(User*)user;
@end
