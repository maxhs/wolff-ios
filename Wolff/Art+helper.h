//
//  Art+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Art.h"
#import "Photo+helper.h"
#import "Artist+helper.h"
#import "Interval+helper.h"

@interface Art (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (void)addPhoto:(Photo*)photo;
- (Photo*)photo;
- (Artist*)primaryArtist;
- (NSString*)materialsToSentence;
- (NSString*)artistsToSentence;
- (NSString*)locationsToSentence;
- (NSString*)tagsToSentence;
@end
