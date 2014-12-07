//
//  Presentation+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Presentation.h"
#import "Slide+helper.h"

@interface Presentation (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (void)addSlide:(Slide*)slide;
@end
