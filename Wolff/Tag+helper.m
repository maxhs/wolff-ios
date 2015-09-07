//
//  Tag+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 4/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "Tag+helper.h"
#import "Photo+helper.h"
#import "Art+helper.h"
#import <MagicalRecord/MagicalRecord.h>

@implementation Tag (helper)

- (void)populateFromDictionary:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]){
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"arts"] && [dictionary objectForKey:@"arts"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"arts"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Art *art = [Art MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!art){
                art = [Art MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [art populateFromDictionary:dict];
            [set addObject:art];
        }
        self.arts = set;
    }
}

- (NSOrderedSet *)photos {
    NSMutableOrderedSet *photos = [NSMutableOrderedSet orderedSet];
    [self.arts enumerateObjectsUsingBlock:^(Art *art, NSUInteger idx, BOOL *stop) {
        [photos addObjectsFromArray:art.photos.array];
    }];
    return photos;
}

- (Photo *)coverPhoto {
    return (self.photos.count ? self.photos.firstObject : nil);
}

@end
