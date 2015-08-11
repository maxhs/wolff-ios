//
//  Slideshow+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Slideshow+helper.h"
#import "Slide+helper.h"
#import "LightTable+helper.h"
#import "User+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Slideshow (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary{
    //NSLog(@"Slideshow helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"title"] && [dictionary objectForKey:@"title"] != [NSNull null]){
        self.title = [dictionary objectForKey:@"title"];
    }
    if ([dictionary objectForKey:@"visible"] && [dictionary objectForKey:@"visible"] != [NSNull null]){
        self.visible = [dictionary objectForKey:@"visible"];
    }
    if ([dictionary objectForKey:@"description"] && [dictionary objectForKey:@"description"] != [NSNull null]){
        self.slideshowDescription = [dictionary objectForKey:@"description"];
    }
    if ([dictionary objectForKey:@"show_title_slide"] && [dictionary objectForKey:@"show_title_slide"] != [NSNull null]){
        self.showTitleSlide = [dictionary objectForKey:@"show_title_slide"];
    }
    if ([dictionary objectForKey:@"show_metadata"] && [dictionary objectForKey:@"show_metadata"] != [NSNull null]){
        self.showMetadata = [dictionary objectForKey:@"show_metadata"];
    }
    if ([dictionary objectForKey:@"slides"] && [dictionary objectForKey:@"slides"] != [NSNull null]){
        NSMutableOrderedSet *slides = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *dict in [dictionary objectForKey:@"slides"]){
            Slide *slide = [Slide MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!slide){
                slide = [Slide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [slide populateFromDictionary:dict];
            [slides addObject:slide];
        }
        for (Slide *slide in self.slides){
            if (![slides containsObject:slide]){
                [slide MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.slides = slides;
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
    if ([dictionary objectForKey:@"public_light_tables"] && [dictionary objectForKey:@"public_light_tables"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"public_light_tables"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            LightTable *lightTable = [LightTable MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!lightTable){
                lightTable = [LightTable MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [lightTable populateFromDictionary:dict];
            [set addObject:lightTable];
        }
        self.lightTables = set;
    }
    
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]){
        NSDictionary *userDict = [dictionary objectForKey:@"user"];
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDictionary:userDict];
        self.user = user;
    }
}

- (void)addPhoto:(Photo *)photo {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tempSet insertObject:photo atIndex:0]; // this ensures we're adding the photo to the TOP of the slideshow light table
    self.photos = tempSet;
}

- (void)removePhoto:(Photo *)photo {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tempSet removeObject:photo];
    self.photos = tempSet;
}

- (void)addSlide:(Slide *)slide atIndex:(NSInteger)index {
    NSMutableOrderedSet *slideSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.slides];
    [slideSet insertObject:slide atIndex:index];
    self.slides = slideSet;
}

- (void)removeSlide:(Slide *)slide fromIndex:(NSInteger)index {
    NSMutableOrderedSet *slideSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.slides];
    if (slide){
        [slideSet removeObject:slide];
    } else {
        [slideSet removeObjectAtIndex:index];
    }
    self.slides = slideSet;
}
@end
