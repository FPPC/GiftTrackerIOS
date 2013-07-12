//
//  Utility.m
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+ (NSString *) getDatabasePath:(NSString *)databaseName {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [documentPaths objectAtIndex:0];
    NSString *databasePath = [documentDir stringByAppendingPathComponent:databaseName];
    return databasePath;
}
@end
