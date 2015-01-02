//
//  Slide+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Slide.h"
#import "Art+helper.h"

@interface Slide (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (void)addArt:(Art*)art;
- (void)removeArt:(Art*)art;
@end
