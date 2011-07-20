//
//  pinch.h
//
//  Retrieve a file from inside a zip file, over the network!
//  ---------------------------------------------------------
//
//  This is the Objective-C implementation of "pinch"
//  Ruby implementation available here: http://peterhellberg.github.com/pinch/
//
//  Dependencies: ASIHTTPRequest, libz.dylib
//
//  Search for "Pinch_Example" in the zipzapper project to find usage examples
//
//  Created by Edward Patel on 2011-05-23.
//  Copyright 2011 Memention AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "zipentry.h"

// 100 eq 1.0.0
#define PINCH_VERSION 100

typedef void(^pinch_file_completion)(zipentry *entry);
typedef void(^pinch_directory_completion)(NSArray *directory);


@interface pinch : NSObject {

}

- (void)fetchFile:(zipentry*)entry completionBlock:(pinch_file_completion)completionBlock;
- (void)fetchDirectory:(NSString*)url completionBlock:(pinch_directory_completion)completionBlock;

@end
