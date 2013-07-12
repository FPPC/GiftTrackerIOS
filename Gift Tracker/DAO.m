//
//  DAO.m
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "DAO.h"

@implementation DAO


-(id)init {
    self = [super init];
    giftAppDelegate * appDelegate = (giftAppDelegate *)[[UIApplication sharedApplication] delegate];
    //setup the db
    self.db = [FMDatabase databaseWithPath:[Utility getDatabasePath:appDelegate.databaseName]];
    [self.db open];
    return self;
}

-(void)dealloc {
    // Yes, even in ARC we can do dealloc, this is solely just to close the db.
    // no releasing needed (it's automatic)
    // no super call needed (automatic too). In fact if you call super here, compiler will stop you
    
    [self.db close];
}

- (NSMutableArray *)getAllSources {
    NSMutableArray * sources = [[NSMutableArray alloc] init];
    //query
    NSString * query = @"SELECT * FROM source;";
    //run
    FMResultSet *results = [self.db executeQuery:query];
    while ([results next]) {
        [sources addObject:[self processResult:results]];
    }
    return sources;
}

- (Source *) processResult:(FMResultSet * )results {
    Source *s = [[Source alloc] init];
    s.idno = [results intForColumn:@"sid"];
    //convention over configuration, @property name should be the same as column name, except the id (which is a reserved word)
    s.name = [results stringForColumn:@"name"];
    s.addr1 = [results stringForColumn:@"addr1"];
    s.addr2 = [results stringForColumn:@"addr2"];
    s.city = [results stringForColumn:@"city"];
    s.state = [results stringForColumn:@"state"];
    s.zip= [results stringForColumn:@"zip"];
    s.business = [results stringForColumn:@"business"];
    s.lobby = ([results intForColumn:@"lobby"] != 0);
    s.email = [results stringForColumn:@"email"];
    s.phone = [results stringForColumn:@"phone"];
    
    return s;
}

-(NSMutableArray *)filterSources:(NSString *)searchString {
    
    if ((searchString == nil) || ([[searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0)) {
        return [self getAllSources];
    }
    NSMutableArray * sources = [[NSMutableArray alloc] init];
    //query
    NSString * query = @"SELECT s.* FROM source s JOIN source_index i ON i.docid = s.sid WHERE i.content match ?";
    FMResultSet *results = [self.db executeQuery:query withArgumentsInArray:[NSArray arrayWithObject:[searchString stringByAppendingString:@"*"]]];
    while ([results next]) {
        [sources addObject:[self processResult:results]];
    }
    return sources;
}

@end