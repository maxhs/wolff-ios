//
//  Partner+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/8/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "Partner+helper.h"
#import "Photo+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "NSArray+ToSentence.h"
#import "Location+helper.h"
#import "WFUtilities.h"

@implementation Partner (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"partner helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]){
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"about"] && [dictionary objectForKey:@"about"] != [NSNull null]){
        self.about = [dictionary objectForKey:@"about"];
    }
    if ([dictionary objectForKey:@"url"] && [dictionary objectForKey:@"url"] != [NSNull null]){
        self.url = [dictionary objectForKey:@"url"];
    }
    if ([dictionary objectForKey:@"avatar_small"] && [dictionary objectForKey:@"avatar_small"] != [NSNull null]){
        self.avatarSmall = [dictionary objectForKey:@"avatar_small"];
    }
    if ([dictionary objectForKey:@"avatar_medium"] && [dictionary objectForKey:@"avatar_medium"] != [NSNull null]){
        self.avatarMedium = [dictionary objectForKey:@"avatar_medium"];
    }
    if ([dictionary objectForKey:@"created_unix"] && [dictionary objectForKey:@"created_unix"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_unix"] doubleValue];
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

@end
