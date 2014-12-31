//
//  Comment+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Comment.h"

@interface Comment (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
@end
