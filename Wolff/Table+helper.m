//
//  Table+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Table+helper.h"
#import "Slideshow+helper.h"
#import "Art+helper.h"
#import "Discussion+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

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
    if ([dict objectForKey:@"slideshows"] && [dict objectForKey:@"slideshows"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dictionary in [dict objectForKey:@"slideshows"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"id"]];
            Slideshow *slideshow = [Slideshow MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!slideshow){
                slideshow = [Slideshow MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [slideshow populateFromDictionary:dictionary];
            [set addObject:slideshow];
        }
        self.slideshows = set;
    }
    if ([dict objectForKey:@"photos"] && [dict objectForKey:@"photos"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dictionary in [dict objectForKey:@"photos"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"id"]];
            Photo *photo = [Photo MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!photo){
                photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [photo populateFromDictionary:dictionary];
            [set addObject:photo];
        }
        self.photos = set;
    }
    if ([dict objectForKey:@"discussions"] && [dict objectForKey:@"discussions"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dictionary in [dict objectForKey:@"discussions"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"id"]];
            Discussion *discussion = [Discussion MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!discussion){
                discussion = [Discussion MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [discussion populateFromDictionary:dictionary];
            [set addObject:discussion];
        }
        self.discussions = set;
    }
}

- (void)addPhoto:(Photo *)photo {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tempSet addObject:photo];
    self.photos = tempSet;
}

- (void)removePhoto:(Photo *)photo {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tempSet removeObject:photo];
    self.photos = tempSet;
}

- (void)addPhotos:(NSArray *)array {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tempSet addObjectsFromArray:array];
    self.photos = tempSet;
}

- (void)removePhotos:(NSArray *)array {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tempSet removeObjectsInArray:array];
    self.photos = tempSet;
}

@end
