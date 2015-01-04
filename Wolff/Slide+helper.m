//
//  Slide+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Slide+helper.h"
#import "Art+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Slide (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"title"] && [dictionary objectForKey:@"title"] != [NSNull null]){
        self.title = [dictionary objectForKey:@"title"];
    }
    if ([dictionary objectForKey:@"index"] && [dictionary objectForKey:@"caption"] != [NSNull null]){
        self.caption = [dictionary objectForKey:@"caption"];
    }
    if ([dictionary objectForKey:@"caption"] && [dictionary objectForKey:@"caption"] != [NSNull null]){
        self.caption = [dictionary objectForKey:@"caption"];
    }
    if ([dictionary objectForKey:@"arts"] && [dictionary objectForKey:@"arts"] != [NSNull null]){
        NSMutableOrderedSet *arts = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *artDict in [dictionary objectForKey:@"arts"]){
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

- (void)addArt:(Art *)art {
    NSMutableOrderedSet *arts = [NSMutableOrderedSet orderedSetWithOrderedSet:self.arts];
    if (![self.arts containsObject:art]){
        [arts addObject:art];
    }
    
    self.arts = arts;
}

- (void)removeArt:(Art*)art {
    NSMutableOrderedSet *arts = [NSMutableOrderedSet orderedSetWithOrderedSet:self.arts];
    [arts removeObject:art];
    self.arts = arts;
}

@end
