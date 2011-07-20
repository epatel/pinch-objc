//
//  zipentry.h (part of pinch)
//
//  Created by Edward Patel on 2011-05-24.
//  Copyright 2011 Memention AB. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface zipentry : NSObject {
    NSString *url;
    NSString *filepath;
    int offset;
    int method;
    int sizeCompressed;
    int sizeUncompressed;
    unsigned int crc32;
    int filenameLength;
    int extraFieldLength;
    NSData *data;
}

@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *filepath;
@property (nonatomic, assign) int offset;
@property (nonatomic, assign) int method;
@property (nonatomic, assign) int sizeCompressed;
@property (nonatomic, assign) int sizeUncompressed;
@property (nonatomic, assign) unsigned int crc32;
@property (nonatomic, assign) int filenameLength;
@property (nonatomic, assign) int extraFieldLength;
@property (nonatomic, retain) NSData *data;

@end
