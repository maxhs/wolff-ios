//
//  Photo+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 10/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Photo+helper.h"

@implementation Photo (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary {
    //NSLog(@"Photo helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"visible"] && [dictionary objectForKey:@"visible"] != [NSNull null]){
        self.visible = [dictionary objectForKey:@"visible"];
    }
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"thumb_image_url"] && [dictionary objectForKey:@"thumb_image_url"] != [NSNull null]){
        self.thumbImageUrl = [dictionary objectForKey:@"thumb_image_url"];
    }
    if ([dictionary objectForKey:@"small_image_url"] && [dictionary objectForKey:@"small_image_url"] != [NSNull null]){
        self.smallImageUrl = [dictionary objectForKey:@"small_image_url"];
    }
    if ([dictionary objectForKey:@"medium_image_url"] && [dictionary objectForKey:@"medium_image_url"] != [NSNull null]){
        self.mediumImageUrl = [dictionary objectForKey:@"medium_image_url"];
    }
    if ([dictionary objectForKey:@"large_image_url"] && [dictionary objectForKey:@"large_image_url"] != [NSNull null]){
        self.largeImageUrl = [dictionary objectForKey:@"large_image_url"];
    }
    if ([dictionary objectForKey:@"original_image_url"] && [dictionary objectForKey:@"original_image_url"] != [NSNull null]){
        self.originalImageUrl = [dictionary objectForKey:@"original_image_url"];
    }
}
@end
