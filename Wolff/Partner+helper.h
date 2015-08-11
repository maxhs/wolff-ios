//
//  Partner+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/8/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "Partner.h"

@interface Partner (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (NSString *)locationsToSentence;
@end
