//
//  Table+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Table+helper.h"

@implementation Table (helper)

- (void)populateFromDictionary:(NSDictionary*)dict {
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"description"] && [dict objectForKey:@"description"] != [NSNull null]){
        self.tableDescription = [dict objectForKey:@"description"];
    }
    if ([dict objectForKey:@"name"] && [dict objectForKey:@"name"] != [NSNull null]){
        self.name = [dict objectForKey:@"name"];
    }
    if ([dict objectForKey:@"visible"] && [dict objectForKey:@"visible"] != [NSNull null]){
        self.visible = [dict objectForKey:@"visible"];
    }
    if ([dict objectForKey:@"private"] && [dict objectForKey:@"private"] != [NSNull null]){
        self.privateTable = [dict objectForKey:@"private"];
    }
}


@end
