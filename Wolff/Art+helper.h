//
//  Art+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Art.h"
#import "Photo+helper.h"

@interface Art (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (Photo*)photo;
@end
