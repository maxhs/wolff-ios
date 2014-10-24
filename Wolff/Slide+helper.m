//
//  Slide+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Slide+helper.h"
#import "Art+helper.h"

@implementation Slide (helper)
- (void)populateFromDictionary:(NSDictionary *)dict {
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"title"] && [dict objectForKey:@"title"] != [NSNull null]){
        self.title = [dict objectForKey:@"title"];
    }
    if ([dict objectForKey:@"caption"] && [dict objectForKey:@"caption"] != [NSNull null]){
        self.caption = [dict objectForKey:@"caption"];
    }
    if ([dict objectForKey:@"arts"] && [dict objectForKey:@"arts"] != [NSNull null]){
        NSMutableOrderedSet *arts = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *artDict in [dict objectForKey:@"arts"]){
            Art *art = [Art MR_findFirstByAttribute:@"identifier" withValue:[artDict objectForKey:@"id"]inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!art){
                art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [art populateFromDictionary:artDict];
            [arts addObject:art];
        }
        self.arts = arts;
    }
}
@end
