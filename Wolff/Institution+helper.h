//
//  Institution+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 10/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Institution.h"
#import "User+helper.h"

@interface Institution (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (void)addUser:(User*)user;
- (void)removeUser:(User*)user;
@end
