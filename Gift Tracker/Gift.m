//
//  Gift.m
//  Gift Tracker
//
//  Created by Tam Do on 7/17/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "Gift.h"
#import "Contribution.h"
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

-(Contribution *)findContributionFromSourceId:(NSUInteger)sid {
    for(int i = 0; i < [self.contributions count]; i++) {
        if (((Contribution *)self.contributions[i]).sid == sid) {
            return self.contributions[i];
        }
    }
    return nil;
}

@end
