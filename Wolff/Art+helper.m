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
#import "LightTable+helper.h"
#import "Citation+helper.h"
#import "Location+helper.h"
#import "Movement+helper.h"
#import "Institution+helper.h"
#import "Interval+helper.h"
#import "Icon+helper.h"
#import "Tag+helper.h"
#import "User+helper.h"
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
    if ([dictionary objectForKey:@"notes"] && [dictionary objectForKey:@"notes"] != [NSNull null]){
        self.notes = [dictionary objectForKey:@"notes"];
    }
    if ([dictionary objectForKey:@"not_extant"] && [dictionary objectForKey:@"not_extant"] != [NSNull null]){
        self.notExtant = [dictionary objectForKey:@"not_extant"];
    }
    if ([dictionary objectForKey:@"private"] && [dictionary objectForKey:@"private"] != [NSNull null]){
        self.privateArt = [dictionary objectForKey:@"private"];
    }
    if ([dictionary objectForKey:@"visible"] && [dictionary objectForKey:@"visible"] != [NSNull null]){
        self.visible = [dictionary objectForKey:@"visible"];
    }
    if ([dictionary objectForKey:@"flagged"] && [dictionary objectForKey:@"flagged"] != [NSNull null]){
        self.flagged = [dictionary objectForKey:@"flagged"];
    }
    if ([dictionary objectForKey:@"height"] && [dictionary objectForKey:@"height"] != [NSNull null]){
        self.height = [dictionary objectForKey:@"height"];
    }
    if ([dictionary objectForKey:@"width"] && [dictionary objectForKey:@"width"] != [NSNull null]){
        self.width = [dictionary objectForKey:@"width"];
    }
    if ([dictionary objectForKey:@"depth"] && [dictionary objectForKey:@"depth"] != [NSNull null]){
        self.depth = [dictionary objectForKey:@"depth"];
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
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]){
        NSDictionary *dict = [dictionary objectForKey:@"user"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        User *user = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDictionary:dict];
        self.user = user;
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
    if ([dictionary objectForKey:@"icons"] && [dictionary objectForKey:@"icons"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"icons"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Icon *icon = [Icon MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!icon){
                icon = [Icon MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [icon populateFromDictionary:dict];
            [set addObject:icon];
        }
        self.icons = set;
    }
    if ([dictionary objectForKey:@"tags"] && [dictionary objectForKey:@"tags"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"tags"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Tag *tag = [Tag MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!tag){
                tag = [Tag MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [tag populateFromDictionary:dict];
            [set addObject:tag];
        }
        self.tags = set;
    }
}

- (void)addPhoto:(Photo *)photo {
    NSMutableOrderedSet *photos = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [photos addObject:photo];
    self.photos = photos;
}

- (Photo *)photo {
    return (self.photos.count ? self.photos.firstObject : nil);
}

- (Artist*)primaryArtist {
    return self.artists.firstObject;
}

- (NSString *)materialsToSentence {
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:self.materials.count];
    [self.materials enumerateObjectsUsingBlock:^(Material *material, NSUInteger idx, BOOL *stop) {
        [names addObject:material.name];
    }];
    return [names toSentence];
}

- (NSString *)artistsToSentence {
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:self.artists.count];
    [self.artists enumerateObjectsUsingBlock:^(Artist *artist, NSUInteger idx, BOOL *stop) {
        [names addObject:artist.name];
    }];
    return [names toSentence];
}

- (NSString *)tagsToSentence {
    NSMutableArray *tags = [NSMutableArray arrayWithCapacity:self.tags.count];
    [self.tags enumerateObjectsUsingBlock:^(Tag *tag, NSUInteger idx, BOOL *stop) {
        [tags addObject:tag.name];
    }];
    return [tags toSentence];
}

- (NSString *)creditsToSentence {
    NSMutableArray *credits = [NSMutableArray array];
    [self.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
        [credits addObject:photo.credit];
    }];
    return [credits toSentence];
}

- (NSString *)locationsToSentence {
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:self.locations.count];
    [self.locations enumerateObjectsUsingBlock:^(Location *location, NSUInteger idx, BOOL *stop) {
        if (location.name.length){
            if (location.city.length){
                [names addObject:[NSString stringWithFormat:@"%@ (%@)",location.name, location.city]];
            } else if (location.country.length){
                [names addObject:[NSString stringWithFormat:@"%@ (%@)",location.name, location.country]];
            } else {
                [names addObject:location.name];
            }
        } else if (location.city.length){
            [names addObject:location.city];
        } else if (location.state.length){
            [names addObject:location.state];
        } else if (location.country.length){
            [names addObject:location.country];
        }
    }];
    return [names toSentence];
}

- (NSString*)readableDate {
    if (self.interval.single){
        //check exact date
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
        return [dateFormatter stringFromDate:self.interval.single];
    } else if (self.interval.beginRange && ![self.interval.beginRange isEqualToNumber:@0] && self.interval.endRange && ![self.interval.endRange isEqualToNumber:@0]) {
        //check for range
        NSString *beginSuffix = self.interval.beginSuffix.length ? self.interval.beginSuffix : @"CE";
        NSString *endSuffix = self.interval.endSuffix.length ? self.interval.endSuffix : @"CE";
        return [NSString stringWithFormat:@"%@ %@ - %@ %@",self.interval.beginRange, beginSuffix, self.interval.endRange, endSuffix];
    } else if (self.interval.year && ![self.interval.year isEqualToNumber:@0]){
        NSString *suffix = self.interval.suffix.length ? self.interval.suffix : @"CE";
        return [NSString stringWithFormat:@"%@ %@",self.interval.year, suffix];
    } else {
        return @"No date listed";
    }
}

- (NSString*)readableDimensions {
    if (![self.width isEqualToNumber:@0] && ![self.height isEqualToNumber:@0] && ![self.depth isEqualToNumber:@0]){
        return [NSString stringWithFormat:@"%@ x %@ x %@",self.width, self.height, self.depth];
    } else {
        return nil;
    }
}

@end
