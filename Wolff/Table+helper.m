//
//  Table+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Table+helper.h"
#import "Presentation+helper.h"
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
    if ([dict objectForKey:@"presentations"] && [dict objectForKey:@"presentations"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dictionary in [dict objectForKey:@"presentations"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"id"]];
            Presentation *presentation = [Presentation MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!presentation){
                presentation = [Presentation MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [presentation populateFromDictionary:dictionary];
            [set addObject:presentation];
        }
        self.presentations = set;
    }
    if ([dict objectForKey:@"arts"] && [dict objectForKey:@"arts"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dictionary in [dict objectForKey:@"arts"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"id"]];
            Art *art = [Art MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!art){
                art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [art populateFromDictionary:dictionary];
            [set addObject:art];
        }
        self.arts = set;
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

- (void)addArt:(Art *)art {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.arts];
    [tempSet addObject:art];
    self.arts = tempSet;
}

- (void)removeArt:(Art *)art {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.arts];
    [tempSet removeObject:art];
    self.arts = tempSet;
}

@end
