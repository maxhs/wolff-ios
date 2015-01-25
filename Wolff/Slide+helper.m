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
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]){
        NSMutableOrderedSet *photos = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *photoDict in [dictionary objectForKey:@"photos"]){
            Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[photoDict objectForKey:@"id"]inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!photo){
                photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [photo populateFromDictionary:photoDict];
            [photos addObject:photo];
        }
        self.photos = photos;
    }
}

- (void)addPhoto:(Photo *)photo {
    NSMutableOrderedSet *photos = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    if ([self.photos containsObject:photo]){
        
    }
    [photos addObject:photo];
    self.photos = photos;
}

- (void)removePhoto:(Photo*)photo {
    NSMutableOrderedSet *photos = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [photos removeObject:photo];
    self.photos = photos;
}

- (void)replacePhotoAtIndex:(NSInteger)index withPhoto:(Photo *)photo {
    NSMutableOrderedSet *photos = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [photos removeObjectAtIndex:index];
    [photos insertObject:photo atIndex:index];
    self.photos = photos;
}

@end
