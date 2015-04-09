//
//  PhotoSlide+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 3/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "PhotoSlide.h"

@interface PhotoSlide (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (BOOL)hasValidFrame;
- (void)resetFrame;
@end
