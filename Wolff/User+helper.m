//
//  User+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "User+helper.h"
#import "Institution+helper.h"
#import "Slideshow+helper.h"
#import "LightTable+helper.h"
#import "Alternate+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "WFUtilities.h"
#import "Constants.h"
#import "Card+helper.h"
#import "NSArray+ToSentence.h"

typedef enum {
    WFPrefixMr = 1,
    WFPrefixMrs = 2,
    WFPrefixMs = 3,
    WFPrefixDr = 4,
    WFPrefixProf = 5,
} WFUserPrefix;

@implementation User (helper)

- (void)populateFromDictionary:(NSDictionary*)dictionary {
    //NSLog(@"user helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"mobile_tokens"] && [dictionary objectForKey:@"mobile_tokens"] != [NSNull null]){
        for (id dict in [dictionary objectForKey:@"mobile_tokens"]){
            //ipad stuff!
            if (IDIOM == IPAD && [[dict objectForKey:@"device_type"] isEqualToNumber:@2]){
                self.mobileToken = [dict objectForKey:@"token"];
                [[NSUserDefaults standardUserDefaults] setObject:self.mobileToken forKey:kUserDefaultsiPadToken];
            } else if ([[dict objectForKey:@"device_type"] isEqualToNumber:@1]) {
                self.mobileToken = [dict objectForKey:@"token"];
                [[NSUserDefaults standardUserDefaults] setObject:self.mobileToken forKey:kUserDefaultsiPhoneToken];
            }
        }
    }
    if ([dictionary objectForKey:@"created_at"] && [dictionary objectForKey:@"created_at"] != [NSNull null]) {
        self.createdDate = [WFUtilities parseDateTime:[dictionary objectForKey:@"created_at"]];
    }
    if ([dictionary objectForKey:@"first_name"] && [dictionary objectForKey:@"first_name"] != [NSNull null]){
        self.firstName = [dictionary objectForKey:@"first_name"];
    }
    if ([dictionary objectForKey:@"last_name"] && [dictionary objectForKey:@"last_name"] != [NSNull null]){
        self.lastName = [dictionary objectForKey:@"last_name"];
    }
    if ([dictionary objectForKey:@"bio"] && [dictionary objectForKey:@"bio"] != [NSNull null]){
        self.bio = [dictionary objectForKey:@"bio"];
    }
    if ([dictionary objectForKey:@"location"] && [dictionary objectForKey:@"location"] != [NSNull null]){
        self.location = [dictionary objectForKey:@"location"];
    }
    if ([dictionary objectForKey:@"url"] && [dictionary objectForKey:@"url"] != [NSNull null]){
        self.url = [dictionary objectForKey:@"url"];
    }
    if ([dictionary objectForKey:@"customer_plan"] && [dictionary objectForKey:@"customer_plan"] != [NSNull null]){
        self.customerPlan = [dictionary objectForKey:@"customer_plan"];
    }
    if ([dictionary objectForKey:@"prefix"] && [dictionary objectForKey:@"prefix"] != [NSNull null]){
        switch ([(NSNumber*)[dictionary objectForKey:@"prefix"] integerValue]) {
            case 0:
                self.prefix = @"";
                break;
            case 1:
                self.prefix = @"Mr.";
                break;
            case 2:
                self.prefix = @"Mrs.";
                break;
            case 3:
                self.prefix = @"Ms.";
                break;
            case 4:
                self.prefix = @"Dr.";
                break;
            case 5:
                self.prefix = @"Prof.";
                break;
                
            default:
                break;
        }
    } else self.prefix = @"";
    
    if ([dictionary objectForKey:@"email"] && [dictionary objectForKey:@"email"] != [NSNull null]){
        self.email = [dictionary objectForKey:@"email"];
    }
    if ([dictionary objectForKey:@"email_permission"] && [dictionary objectForKey:@"email_permission"] != [NSNull null]){
        self.emailPermission = [dictionary objectForKey:@"email_permission"];
    }
    if ([dictionary objectForKey:@"push_permission"] && [dictionary objectForKey:@"push_permission"] != [NSNull null]){
        self.pushPermission = [dictionary objectForKey:@"push_permission"];
    }
    if ([dictionary objectForKey:@"text_permission"] && [dictionary objectForKey:@"text_permission"] != [NSNull null]){
        self.textPermission = [dictionary objectForKey:@"text_permission"];
    }
    if ([dictionary objectForKey:@"avatar_small"] && [dictionary objectForKey:@"avatar_small"] != [NSNull null]) {
        self.avatarSmall = [dictionary objectForKey:@"avatar_small"];
    }
    if ([dictionary objectForKey:@"avatar_large"] && [dictionary objectForKey:@"avatar_large"] != [NSNull null]) {
        self.avatarLarge = [dictionary objectForKey:@"avatar_large"];
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
    
    if ([dictionary objectForKey:@"private_photos"] && [dictionary objectForKey:@"private_photos"] != [NSNull null]){
        //NSLog(@"private photos: %@",[dictionary objectForKey:@"private_photos"]);
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"private_photos"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Photo *photo = [Photo MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!photo){
                photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [photo populateFromDictionary:dict];
            photo.privatePhoto = @YES;
            [set addObject:photo];
        }
    }
    
    if ([dictionary objectForKey:@"slideshows"] && [dictionary objectForKey:@"slideshows"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"slideshows"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Slideshow *slideshow = [Slideshow MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!slideshow){
                slideshow = [Slideshow MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [slideshow populateFromDictionary:dict];
            [set addObject:slideshow];
        }
        for (Slideshow *slideshow in self.slideshows){
            if (![set containsObject:slideshow]){
                [slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.slideshows = set;
    }
    if ([dictionary objectForKey:@"public_slideshows"] && [dictionary objectForKey:@"public_slideshows"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"public_slideshows"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Slideshow *slideshow = [Slideshow MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!slideshow){
                slideshow = [Slideshow MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [slideshow populateFromDictionary:dict];
            [set addObject:slideshow];
        }
        for (Slideshow *slideshow in self.slideshows){
            if (![set containsObject:slideshow]){
                [slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.slideshows = set;
    }
    
    if ([dictionary objectForKey:@"light_tables"] && [dictionary objectForKey:@"light_tables"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"light_tables"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            LightTable *table = [LightTable MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!table){
                table = [LightTable MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [table populateFromDictionary:dict];
            [set addObject:table];
        }
        for (LightTable *table in self.lightTables){
            if (![set containsObject:table]){
                [table MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.lightTables = set;
    }
    
    if ([dictionary objectForKey:@"public_light_tables"] && [dictionary objectForKey:@"public_light_tables"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"public_light_tables"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            LightTable *table = [LightTable MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!table){
                table = [LightTable MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [table populateFromDictionary:dict];
            [set addObject:table];
        }
        for (LightTable *table in self.lightTables){
            if (![set containsObject:table]){
                [table MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.lightTables = set;
    }
    
    if ([dictionary objectForKey:@"institutions"] && [dictionary objectForKey:@"institutions"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"institutions"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Institution *institution = [Institution MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!institution){
                institution = [Institution MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [institution populateFromDictionary:dict];
            [set addObject:institution];
        }
        self.institutions = set;
    }
    
    if ([dictionary objectForKey:@"cards"] && [dictionary objectForKey:@"cards"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"cards"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Card *card = [Card MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!card){
                card = [Card MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [card populateFromDictionary:dict];
            [set addObject:card];
        }
        self.cards = set;
    }
    
    if ([dictionary objectForKey:@"favorites"] && [dictionary objectForKey:@"favorites"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"favorites"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Favorite *favorite = [Favorite MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!favorite){
                favorite = [Favorite MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [favorite populateFromDictionary:dict];
            [set addObject:favorite];
        }
        for (Favorite *favorite in self.favorites){
            if (![set containsObject:favorite]){
                NSLog(@"deleting a favorite: %@",favorite.photo.art.title);
                [favorite MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.favorites = set;
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
    if ([dictionary objectForKey:@"public_photos"] && [dictionary objectForKey:@"public_photos"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"public_photos"]){
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
    
    if ([dictionary objectForKey:@"alternates"] && [dictionary objectForKey:@"alternates"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"alternates"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Alternate *alternate = [Alternate MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!alternate){
                alternate = [Alternate MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [alternate populateFromDictionary:dict];
            [set addObject:alternate];
        }
        for (Alternate *alternate in self.alternates){
            if (![set containsObject:alternate]){
                [alternate MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.alternates = set;
    }
}

- (NSString*) fullName {
    if (self.firstName.length){
        if (self.lastName.length) {
            return [NSString stringWithFormat:@"%@ %@",self.firstName, self.lastName];
        } else {
            return self.firstName;
        }
    } else if (self.email.length) {
        return self.email;
    } else {
        return @"";
    }
}

- (Institution*)institution {
    if (self.institutions.count){
        return self.institutions.firstObject;
    } else {
        return nil;
    }
}

- (NSString *)institutionsToSentence {
    NSMutableArray *institutions = [NSMutableArray arrayWithCapacity:self.institutions.count];
    [self.institutions enumerateObjectsUsingBlock:^(Institution *institution, NSUInteger idx, BOOL *stop) {
        [institutions addObject:institution.name];
    }];
    return [institutions toSentence];
}


- (Favorite *)getFavoriteArt:(Art *)art {
    __block Favorite *favorite = nil;
    [self.favorites enumerateObjectsUsingBlock:^(Favorite *fav, NSUInteger idx, BOOL *stop) {
        if (fav.art && [fav.art.identifier isEqualToNumber:art.identifier]){
            favorite = fav;
            *stop = YES;
        }
    }];
    return favorite;
}


- (Favorite *)getFavoritePhoto:(Photo *)photo {
    __block Favorite *favorite = nil;
    [self.favorites enumerateObjectsUsingBlock:^(Favorite *fav, NSUInteger idx, BOOL *stop) {
        if (fav.photo && photo.identifier && [fav.photo.identifier isEqualToNumber:photo.identifier]){
            favorite = fav;
            *stop = YES;
        }
    }];
    return favorite;
}

- (void)addFavorite:(Favorite *)favorite {
    NSMutableOrderedSet *favorites = [NSMutableOrderedSet orderedSetWithOrderedSet:self.favorites];
    [favorites addObject:favorite];
    self.favorites = favorites;
}

- (void)removeFavorite:(Favorite *)favorite {
    NSMutableOrderedSet *favorites = [NSMutableOrderedSet orderedSetWithOrderedSet:self.favorites];
    [favorites removeObject:favorite];
    self.favorites = favorites;
}

- (void)addLightTable:(LightTable *)lightTable {
    NSMutableOrderedSet *lightTables = [NSMutableOrderedSet orderedSetWithOrderedSet:self.lightTables];
    [lightTables addObject:lightTable];
    self.lightTables = lightTables;
}

- (void)removeLightTable:(LightTable *)lightTable {
    NSMutableOrderedSet *lightTables = [NSMutableOrderedSet orderedSetWithOrderedSet:self.lightTables];
    [lightTables removeObject:lightTable];
    self.lightTables = lightTables;
}

- (void)addInstitution:(Institution *)institution {
    NSMutableOrderedSet *institutions = [NSMutableOrderedSet orderedSetWithOrderedSet:self.institutions];
    [institutions addObject:institution];
    self.institutions = institutions;
}

- (void)removeInstitution:(Institution *)institution {
    NSMutableOrderedSet *institutions = [NSMutableOrderedSet orderedSetWithOrderedSet:self.institutions];
    [institutions removeObject:institution];
    self.institutions = institutions;
}

- (void)removeSlideshow:(Slideshow *)slideshow {
    NSMutableOrderedSet *slideshows = [NSMutableOrderedSet orderedSetWithOrderedSet:self.slideshows];
    [slideshows removeObject:slideshow];
    self.slideshows = slideshows;
}

- (void)addCard:(Card *)card {
    NSMutableOrderedSet *cards = [NSMutableOrderedSet orderedSetWithOrderedSet:self.cards];
    [cards removeObject:card];
    self.cards = cards;
}

- (void)removeCard:(Card *)card {
    NSMutableOrderedSet *cards = [NSMutableOrderedSet orderedSetWithOrderedSet:self.cards];
    [cards removeObject:card];
    self.cards = cards;
}

@end
