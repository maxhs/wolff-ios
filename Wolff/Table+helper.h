//
//  Table+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Table.h"
#import "Art+helper.h"

@interface Table (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
- (void)addArt:(Art*)art;
- (void)removeArt:(Art*)art;
@end
