//
//  SlideText+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 3/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

typedef enum {
    WFSlideTextAlignmentCenter  = 0,
    WFSlideTextAlignmentLeft    = 1,
    WFSlideTextAlignmentRight   = 2,
} WFSlideTextAlignment;

#import "SlideText.h"

@interface SlideText (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
@end
