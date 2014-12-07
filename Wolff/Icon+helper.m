//
//  Icon+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Icon+helper.h"

@implementation Icon (helper)
- (void)populateFromDictionary:(NSDictionary*)dict {
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"name"] && [dict objectForKey:@"name"] != [NSNull null]){
        self.name = [dict objectForKey:@"name"];
    }
    if ([dict objectForKey:@"description"] && [dict objectForKey:@"description"] != [NSNull null]){
        self.about = [dict objectForKey:@"description"];
    }
}
@end
