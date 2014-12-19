//
//  Art+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Art+helper.h"
#import "Photo+helper.h"
#import "Artist+helper.h"
#import "Material+helper.h"
#import "Table+helper.h"
#import "Citation+helper.h"
#import "Location+helper.h"
#import "Movement+helper.h"
#import "Interval+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "NSArray+ToSentence.h"

@implementation Art (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"title"] && [dictionary objectForKey:@"title"] != [NSNull null]){
        self.title = [dictionary objectForKey:@"title"];
    }
    if ([dictionary objectForKey:@"not_extant"] && [dictionary objectForKey:@"not_extant"] != [NSNull null]){
        self.notExtant = [dictionary objectForKey:@"not_extant"];
    }
    if ([dictionary objectForKey:@"uploaded_epoch_time"] && [dictionary objectForKey:@"uploaded_epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"uploaded_epoch_time"] doubleValue];
        self.uploadedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
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
    if ([dictionary objectForKey:@"interval"] && [dictionary objectForKey:@"interval"] != [NSNull null]){
        NSDictionary *dict = [dictionary objectForKey:@"interval"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        Interval *interval = [Interval MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!interval){
            interval = [Interval MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [interval populateFromDictionary:dict];
        self.interval = interval;
    }
    if ([dictionary objectForKey:@"artists"] && [dictionary objectForKey:@"artists"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"artists"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Artist *artist = [Artist MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!artist){
                artist = [Artist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [artist populateFromDictionary:dict];
            [set addObject:artist];
        }
        self.artists = set;
    }
    if ([dictionary objectForKey:@"materials"] && [dictionary objectForKey:@"materials"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"materials"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Material *material = [Material MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!material){
                material = [Material MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [material populateFromDictionary:dict];
            NSLog(@"Adding medium with name: %@",material.name);
            [set addObject:material];
        }
        self.materials = set;
    }
    if ([dictionary objectForKey:@"movements"] && [dictionary objectForKey:@"movements"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"movements"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Movement *movement = [Movement MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!movement){
                movement = [Movement MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [movement populateFromDictionary:dict];
            [set addObject:movement];
        }
        self.movements = set;
    }
    if ([dictionary objectForKey:@"citations"] && [dictionary objectForKey:@"citations"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"citations"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Citation *citation = [Citation MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!citation){
                citation = [Citation MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [citation populateFromDictionary:dict];
            [set addObject:citation];
        }
        self.citations = set;
    }
    if ([dictionary objectForKey:@"locations"] && [dictionary objectForKey:@"locations"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"locations"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Location *location = [Location MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!location){
                location = [Location MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [location populateFromDictionary:dict];
            [set addObject:location];
        }
        self.locations = set;
    }
    if ([dictionary objectForKey:@"locations"] && [dictionary objectForKey:@"locations"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"locations"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Location *location = [Location MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!location){
                location = [Location MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [location populateFromDictionary:dict];
            [set addObject:location];
        }
        self.locations = set;
    }
}

- (Photo *)photo {
    return (self.photos.count ? self.photos.firstObject : nil);
}

- (Artist*)primaryArtist {
    return self.artists.firstObject;
}

- (NSString *)mediaToSentence {
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:self.materials.count];
    [self.materials enumerateObjectsUsingBlock:^(Material *material, NSUInteger idx, BOOL *stop) {
        [names addObject:material.name];
    }];
    return [names toSentence];
}

@end
