//
//  Presentation+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Presentation.h"
#import "Art+helper.h"
#import "Slide+helper.h"

@interface Presentation (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (void)addSlide:(Slide*)slide;
- (void)removeSlide:(Slide*)slide;
- (void)addArt:(Art*)art;
- (void)removeArt:(Art*)art;
@end
