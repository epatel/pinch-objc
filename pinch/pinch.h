/*---------------------------------------------------------------------------
 
 pinch.h
 
 Retrieve a file from inside a zip file, over the network!
 ---------------------------------------------------------
 
 This is the Objective-C implementation of "pinch"
 Ruby implementation available here: http://peterhellberg.github.com/pinch/
 
 Dependencies: ASIHTTPRequest or AFNetworking, libz.dylib
 
 Search for "Pinch_Example" in the zipzapper project to find usage examples
 
 https://github.com/epatel/pinch-objc
 
 Copyright (c) 2011-2012 Edward Patel
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 ---------------------------------------------------------------------------*/

#import <Foundation/Foundation.h>
#import "zipentry.h"

// 100 eq 1.0.0
#define PINCH_VERSION 110

// #define PINCH_USE_AFNETWORKING
// #define PINCH_USE_ASIHTTPREQUEST

#ifdef PINCH_USE_AFNETWORKING
#  ifdef PINCH_USE_ASIHTTPREQUEST
#    error Use AFNetworking or ASIHTTPRequest for pinch, not both
#  endif
#endif

#ifndef PINCH_USE_AFNETWORKING
#  ifndef PINCH_USE_ASIHTTPREQUEST
#    error Use AFNetworking or ASIHTTPRequest for pinch, define either PINCH_USE_AFNETWORKING or PINCH_USE_ASIHTTPREQUEST
#  endif
#endif

typedef void(^pinch_file_completion)(zipentry *entry);
typedef void(^pinch_directory_completion)(NSArray *directory);

@interface pinch : NSObject {
#ifdef PINCH_USE_ASIHTTPREQUEST
    BOOL runAsynchronous;
#endif
}

#ifdef PINCH_USE_ASIHTTPREQUEST
@property (nonatomic, assign) BOOL runAsynchronous;
#endif

- (void)fetchFile:(zipentry*)entry completionBlock:(pinch_file_completion)completionBlock;
- (void)fetchDirectory:(NSString*)url completionBlock:(pinch_directory_completion)completionBlock;

@end
