//
//  User+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "User.h"
#import "Art+helper.h"
#import "Photo+helper.h"
#import "Favorite+helper.h"
#import "Table+helper.h"
#import "Slideshow+helper.h"

@interface User (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (NSString *)fullName;
- (Favorite *)getFavoriteArt:(Art*)art;
- (Favorite *)getFavoritePhoto:(Photo*)photo;
- (void)addLightTable:(Table*)lightTable;
- (void)removeLightTable:(Table*)lightTable;
- (void)removeSlideshow:(Slideshow*)slideshow;
@end
