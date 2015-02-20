//
//  Icon+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Icon.h"
#import "Photo+helper.h"

@interface Icon (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (Photo*)coverPhoto;
@end
