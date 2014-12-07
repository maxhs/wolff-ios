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
#import "Medium+helper.h"
#import "Group+helper.h"
#import "Inscription+helper.h"
#import "Location+helper.h"
#import "Movement+helper.h"
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
    if ([dictionary objectForKey:@"mediums"] && [dictionary objectForKey:@"mediums"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"mediums"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Medium *medium = [Medium MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!medium){
                medium = [Medium MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [medium populateFromDictionary:dict];
            NSLog(@"Adding medium with name: %@",medium.name);
            [set addObject:medium];
        }
        self.media = set;
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
    if ([dictionary objectForKey:@"inscriptions"] && [dictionary objectForKey:@"inscriptions"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"inscriptions"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Inscription *inscription = [Inscription MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!inscription){
                inscription = [Inscription MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [inscription populateFromDictionary:dict];
            [set addObject:inscription];
        }
        self.inscriptions = set;
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
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:self.media.count];
    [self.media enumerateObjectsUsingBlock:^(Medium *medium, NSUInteger idx, BOOL *stop) {
        [names addObject:medium.name];
    }];
    return [names toSentence];
}

@end
