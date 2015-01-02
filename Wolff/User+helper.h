//
//  User+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "User.h"
#import "Art+helper.h"
#import "Favorite+helper.h"

@interface User (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (NSString *)fullName;
- (Favorite *)getFavorite:(Art*)art;
@end
