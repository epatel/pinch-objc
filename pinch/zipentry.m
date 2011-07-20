//
//  zipentry.m (part of pinch)
//
//  Created by Edward Patel on 2011-05-24.
//  Copyright 2011 Memention AB. All rights reserved.
//

#import "zipentry.h"


@implementation zipentry

@synthesize url;
@synthesize filepath;
@synthesize offset;
@synthesize method;
@synthesize sizeCompressed;
@synthesize sizeUncompressed;
@synthesize crc32;
@synthesize filenameLength;
@synthesize extraFieldLength;
@synthesize data;

- (void)dealloc
{
    [url release];
    [filepath release];
    [data release];
    [super dealloc];
}

@end
