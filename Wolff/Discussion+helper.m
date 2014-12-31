//
//  Discussion+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Discussion+helper.h"

@implementation Discussion (helper)

- (void)populateFromDictionary:(NSDictionary *)dict{
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"title"] && [dict objectForKey:@"title"] != [NSNull null]){
        self.title = [dict objectForKey:@"title"];
    }
}
@end
