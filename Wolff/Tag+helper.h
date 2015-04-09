//
//  Tag+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 4/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "Tag.h"

@interface Tag (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (NSMutableOrderedSet*)photos;
- (Photo *)coverPhoto;
@end
