//
//  Artist+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Artist+helper.h"
#import "Photo+helper.h"
#import <MagicalRecord/MagicalRecord.h>

@implementation Artist (helper)

- (void)populateFromDictionary:(NSDictionary*)dict {
    //NSLog(@"artist helper: %@",dict);
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"name"] && [dict objectForKey:@"name"] != [NSNull null]){
        self.name = [dict objectForKey:@"name"];
    }
    if ([dict objectForKey:@"birth_year"] && [dict objectForKey:@"birth_year"] != [NSNull null]){
        self.birthYear = [dict objectForKey:@"birth_year"];
    }
    if ([dict objectForKey:@"death_year"] && [dict objectForKey:@"death_year"] != [NSNull null]){
        self.deathYear = [dict objectForKey:@"death_year"];
    }
    if ([dict objectForKey:@"cover_photo"] && [dict objectForKey:@"cover_photo"] != [NSNull null]){
        Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[[dict objectForKey:@"cover_photo"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!photo) {
            photo = [Photo MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [photo populateFromDictionary:[dict objectForKey:@"cover_photo"]];
        NSMutableOrderedSet *photos = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
        [photos addObject:photo];
        self.photos = photos;
    }
}
@end
