//
//  Folder+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Folder+helper.h"

@implementation Folder (helper)

- (void)populateFromDictionary:(NSDictionary*)dict {
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
}

@end
