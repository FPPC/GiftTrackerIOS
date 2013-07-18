//
//  Gift.m
//  Gift Tracker
//
//  Created by Tam Do on 7/17/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "Gift.h"

@implementation Gift

@synthesize description, date, contributions, idno;

-(id)init {
    self = [super init];
    self.contributions = [[NSMutableArray alloc] init];
    return self;
}


-(NSComparisonResult)compare:(Gift *)otherGift {
    return [self.date compare:otherGift.date];
}
@end
