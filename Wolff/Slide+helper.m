//
//  Slide+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Slide+helper.h"
#import "SlideText+helper.h"
#import "PhotoSlide+helper.h"
#import "Art+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Slide (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"slide helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"title"] && [dictionary objectForKey:@"title"] != [NSNull null]){
        self.title = [dictionary objectForKey:@"title"];
    }
    if ([dictionary objectForKey:@"index"] && [dictionary objectForKey:@"index"] != [NSNull null]){
        self.index = [dictionary objectForKey:@"index"];
    }
    if ([dictionary objectForKey:@"photo_slides"] && [dictionary objectForKey:@"photo_slides"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *photoDict in [dictionary objectForKey:@"photo_slides"]){
            PhotoSlide *photoSlide = [PhotoSlide MR_findFirstByAttribute:@"identifier" withValue:[photoDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!photoSlide){
                photoSlide = [PhotoSlide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [photoSlide populateFromDictionary:photoDict];
            photoSlide.slide = self;
            [set addObject:photoSlide];
        }
        for (PhotoSlide *photoSlide in self.photoSlides){
            if (![set containsObject:photoSlide]){
                [photoSlide MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.photoSlides = set;
    }
    if ([dictionary objectForKey:@"slide_texts"] && [dictionary objectForKey:@"slide_texts"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *textDict in [dictionary objectForKey:@"slide_texts"]){
            SlideText *slideText = [SlideText MR_findFirstByAttribute:@"identifier" withValue:[textDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!slideText){
                slideText = [SlideText MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [slideText populateFromDictionary:textDict];
            [set addObject:slideText];
        }
        for (SlideText *slideText in self.slideTexts){
            if (![set containsObject:slideText]){
                [slideText MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.slideTexts = set;
    }
}

- (void)addPhotoSlide:(PhotoSlide *)photoSlide {
    NSMutableOrderedSet *photoSlides = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photoSlides];
    [photoSlides addObject:photoSlide];
    self.photoSlides = photoSlides;
}

- (void)removePhotoSlide:(PhotoSlide *)photoSlide {
    NSMutableOrderedSet *photoSlides = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photoSlides];
    [photoSlides removeObject:photoSlide];
    self.photoSlides = photoSlides;
}

- (void)replacePhotoSlideAtIndex:(NSInteger)index withPhotoSlide:(PhotoSlide *)photoSlide {
    NSMutableOrderedSet *photoSlides = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photoSlides];
    [photoSlides removeObjectAtIndex:index];
    [photoSlides insertObject:photoSlide atIndex:index];
    self.photoSlides = photoSlides;
}

- (NSOrderedSet *)photos {
    NSMutableOrderedSet *photos = [NSMutableOrderedSet orderedSetWithCapacity:self.photoSlides.count];
    [self.photoSlides enumerateObjectsUsingBlock:^(PhotoSlide *photoSlide, NSUInteger idx, BOOL *stop) {
        [photos addObject:photoSlide.photo];
    }];
    return photos;
}

@end
