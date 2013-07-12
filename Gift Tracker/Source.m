//
//  Source.m
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "Source.h"

@implementation Source
@synthesize name, addr1, addr2, city, state, zip, business, lobby, email, phone;

-(id)init {
    self = [super init];
    self.limitLeft = 0;
    return self;
}

-(NSComparisonResult)compare:(Source *)otherSource {
    return (self.limitLeft < otherSource.limitLeft) ? NSOrderedAscending :(self.limitLeft==otherSource.limitLeft)?NSOrderedSame:NSOrderedDescending;
}
@end
