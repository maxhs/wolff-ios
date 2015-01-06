//
//  Table+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Table.h"
#import "Photo+helper.h"

@interface Table (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (void)addPhoto:(Photo*)photo;
- (void)removePhoto:(Photo*)photo;
- (void)addPhotos:(NSArray*)array;
- (void)removePhotos:(NSArray*)array;
@end
