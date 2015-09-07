//
//  Institution+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 10/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Institution+helper.h"
#import "Art+helper.h"
#import <MagicalRecord/MagicalRecord.h>

@implementation Institution (helper)

- (void)populateFromDictionary:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]){
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"blurb"] && [dictionary objectForKey:@"blurb"] != [NSNull null]){
        self.blurb = [dictionary objectForKey:@"blurb"];
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

- (void)addUser:(User *)user {
    NSMutableOrderedSet *users = [NSMutableOrderedSet orderedSetWithOrderedSet:self.users];
    [users addObject:user];
    self.users = users;
}

- (void)removeUser:(User *)user {
    NSMutableOrderedSet *users = [NSMutableOrderedSet orderedSetWithOrderedSet:self.users];
    [users removeObject:user];
    self.users = users;
}

@end
