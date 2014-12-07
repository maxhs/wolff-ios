//
//  Institution+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 10/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Institution+helper.h"
#import "Art+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Institution (helper)

- (void)populateFromDictionary:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    
    if ([dictionary objectForKey:@"arts"] && [dictionary objectForKey:@"arts"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"arts"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Art *art = [Art MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!art){
                art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [art populateFromDictionary:dict];
            [set addObject:art];
        }
        self.arts = set;
    }
    
}

@end
