//
//  Material+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Material+helper.h"
#import "Art+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Material (helper)

- (void)populateFromDictionary:(NSDictionary*)dict {
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"name"] && [dict objectForKey:@"name"] != [NSNull null]){
        self.name = [dict objectForKey:@"name"];
    }
    if ([dict objectForKey:@"description"] && [dict objectForKey:@"description"] != [NSNull null]){
        self.about = [dict objectForKey:@"description"];
    }
    if ([dict objectForKey:@"arts"] && [dict objectForKey:@"arts"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id artDict in [dict objectForKey:@"arts"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Art *art = [Art MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!art){
                art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [art populateFromDictionary:artDict];
            [set addObject:art];
        }
        self.arts = set;
    }
}

@end
