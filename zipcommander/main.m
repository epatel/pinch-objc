//
//  main.m
//  zipcommander
//
//  Created by Edward Patel on 2011-08-14.
//  Copyright 2011 Memention AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pinch.h"

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    pinch *p = [[pinch alloc] init];
    
    // Pinch_Example: We don't have a run loop so lets run pinch synchronous
    
    p.runAsynchronous = NO; 
    
    __block NSArray *directory = nil;
    
    NSString *url = @"http://memention.com/ericjohnson-canabalt-ios-ef43b7d.zip";
    
    // Pinch_Example: Get the directory
    
    [p fetchDirectory:url
      completionBlock:^(NSArray *array) {
          directory = array;
          [directory retain];
      }];
        
    // Want to list the entries?

    //    for (zipentry *entry in directory) {
    //        NSLog(@"%@", entry.filepath);
    //    }
        
    // Pinch_Example: Get a file

    zipentry *entry = [directory zipentryWithPath:@"ericjohnson-canabalt-ios-ef43b7d/README.TXT"];
    
    if (entry) {
        [p fetchFile:entry completionBlock:^(zipentry *entry) {
            NSData *data = entry.data;
            if (data) 
                NSLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
        }];
    }
    
    [pool drain];
    return 0;
}

