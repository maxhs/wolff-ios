//
//  Art+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Art+helper.h"
#import "Photo+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Art (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"title"] && [dictionary objectForKey:@"title"] != [NSNull null]){
        self.title = [dictionary objectForKey:@"title"];
    }
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"photos"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Photo *photo = [Photo MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!photo){
                photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [photo populateFromDictionary:dict];
            [set addObject:photo];
        }
        self.photos = set;
    }
}

- (Photo *)photo {
    return (self.photos.count ? self.photos.firstObject : nil);
}
@end
