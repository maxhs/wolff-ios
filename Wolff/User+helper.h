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
#import "LightTable+helper.h"
#import "Slideshow+helper.h"
#import "Institution+helper.h"
#import "Card+helper.h"

@interface User (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (NSString *)fullName;
- (Institution*)institution;
- (NSString*)institutionsToSentence;
- (Favorite *)getFavoriteArt:(Art*)art;
- (Favorite *)getFavoritePhoto:(Photo*)photo;
- (void)addFavorite:(Favorite*)favorite;
- (void)removeFavorite:(Favorite*)favorite;
- (void)addLightTable:(LightTable*)lightTable;
- (void)removeLightTable:(LightTable*)lightTable;
- (void)addInstitution:(Institution*)institution;
- (void)removeInstitution:(Institution*)institution;
- (void)removeSlideshow:(Slideshow*)slideshow;
- (void)addCard:(Card*)card;
- (void)removeCard:(Card*)card;
@end
