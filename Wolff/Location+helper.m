//
//  Location+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 10/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Location+helper.h"

@implementation Location (helper)

- (void)populateFromDictionary:(NSDictionary*)dict {
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"name"] && [dict objectForKey:@"name"] != [NSNull null]){
        self.name = [dict objectForKey:@"name"];
    }
    if ([dict objectForKey:@"in_situ"] && [dict objectForKey:@"in_situ"] != [NSNull null]){
        self.inSitu = [dict objectForKey:@"in_situ"];
    }
    if ([dict objectForKey:@"original"] && [dict objectForKey:@"original"] != [NSNull null]){
        self.original = [dict objectForKey:@"original"];
    }
    
}

@end
