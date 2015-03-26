//
//  SlideText+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 3/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "SlideText+helper.h"

@implementation SlideText (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    NSLog(@"Slide text helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]){
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"font"] && [dictionary objectForKey:@"font"] != [NSNull null]){
        self.font = [dictionary objectForKey:@"font"];
    }
    if ([dictionary objectForKey:@"font_size"] && [dictionary objectForKey:@"font_size"] != [NSNull null]){
        self.fontSize = [dictionary objectForKey:@"font_size"];
    }
}
@end
