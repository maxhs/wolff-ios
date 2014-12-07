//
//  Inscription+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Inscription+helper.h"

@implementation Inscription (helper)

- (void)populateFromDictionary:(NSDictionary*)dict {
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"body"] && [dict objectForKey:@"body"] != [NSNull null]){
        self.body = [dict objectForKey:@"body"];
    }
}


@end
