//
//  Location+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 10/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Location+helper.h"

@implementation Location (helper)

- (void)populateFromDictionary:(NSDictionary*)dict {
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"name"] && [dict objectForKey:@"name"] != [NSNull null]){
        self.name = [dict objectForKey:@"name"];
    }
    if ([dict objectForKey:@"in_situ"] && [dict objectForKey:@"in_situ"] != [NSNull null]){
        self.inSitu = [dict objectForKey:@"in_situ"];
    }
    if ([dict objectForKey:@"original"] && [dict objectForKey:@"original"] != [NSNull null]){
        self.original = [dict objectForKey:@"original"];
    }
    if ([dict objectForKey:@"current"] && [dict objectForKey:@"current"] != [NSNull null]){
        self.current = [dict objectForKey:@"current"];
    }
    if ([dict objectForKey:@"city"] && [dict objectForKey:@"city"] != [NSNull null]){
        self.city = [dict objectForKey:@"city"];
    }
    if ([dict objectForKey:@"state"] && [dict objectForKey:@"state"] != [NSNull null]){
        self.state = [dict objectForKey:@"state"];
    }
    if ([dict objectForKey:@"country"] && [dict objectForKey:@"country"] != [NSNull null]){
        self.country = [dict objectForKey:@"country"];
    }
    
    if ([dict objectForKey:@"arrival"] && [dict objectForKey:@"arrival"] != [NSNull null]){
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        NSDate *date;
        NSError *error;
        if (![dateFormat getObjectValue:&date forString:[dict objectForKey:@"arrival"] range:nil error:&error]) {
            NSLog(@"Date '%@' could not be parsed: %@", [dict objectForKey:@"arrival"], error);
        }
        self.arrival = date;
    }
    if ([dict objectForKey:@"arrival_day"] && [dict objectForKey:@"arrival_day"] != [NSNull null]){
        self.arrivalDay = [dict objectForKey:@"arrival_day"];
    }
    if ([dict objectForKey:@"arrival_month"] && [dict objectForKey:@"arrival_month"] != [NSNull null]){
        self.arrivalMonth = [dict objectForKey:@"arrival_month"];
    }
    if ([dict objectForKey:@"arrival_year"] && [dict objectForKey:@"arrival_year"] != [NSNull null]){
        self.arrivalYear = [dict objectForKey:@"arrival_year"];
    }
    if ([dict objectForKey:@"departure"] && [dict objectForKey:@"departure"] != [NSNull null]){
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        NSDate *date;
        NSError *error;
        if (![dateFormat getObjectValue:&date forString:[dict objectForKey:@"departure"] range:nil error:&error]) {
            NSLog(@"Date '%@' could not be parsed: %@", [dict objectForKey:@"departure"], error);
        }
        self.departure = date;
    }
    if ([dict objectForKey:@"departure_day"] && [dict objectForKey:@"departure_day"] != [NSNull null]){
        self.departureDay = [dict objectForKey:@"departure_day"];
    }
    if ([dict objectForKey:@"departure_month"] && [dict objectForKey:@"departure_month"] != [NSNull null]){
        self.departureMonth = [dict objectForKey:@"departure_month"];
    }
    if ([dict objectForKey:@"departure_year"] && [dict objectForKey:@"departure_year"] != [NSNull null]){
        self.departureYear = [dict objectForKey:@"departure_year"];
    }
}

@end
