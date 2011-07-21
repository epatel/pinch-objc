/*---------------------------------------------------------------------------
 
 pinch.m
 
 https://github.com/epatel/pinch-objc
 
 Copyright (c) 2011 Edward Patel
 
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

#import "pinch.h"
#import "ASIHTTPRequest.h"
#import "zipentry.h"

#include <zlib.h>
#include <ctype.h>
#include <stdio.h>

typedef unsigned int uint32;
typedef unsigned short uint16;

// The headers, see http://en.wikipedia.org/wiki/ZIP_(file_format)#File_headers
// Note that here they will not be as tightly packed as defined in the file format,
// so the extraction is done with a macro below. 

struct zip_end_record {
    uint32 endOfCentralDirectorySignature;
    uint16 numberOfThisDisk;
    uint16 diskWhereCentralDirectoryStarts;
    uint16 numberOfCentralDirectoryRecordsOnThisDisk;
    uint16 totalNumberOfCentralDirectoryRecords;
    uint32 sizeOfCentralDirectory;
    uint32 offsetOfStartOfCentralDirectory;
    uint16 ZIPfileCommentLength;
};

struct zip_dir_record {
    uint32 centralDirectoryFileHeaderSignature;
    uint16 versionMadeBy;
    uint16 versionNeededToExtract;
    uint16 generalPurposeBitFlag;
    uint16 compressionMethod;
    uint16 fileLastModificationTime;
    uint16 fileLastModificationDate;
    uint32 CRC32;
    uint32 compressedSize;
    uint32 uncompressedSize;
    uint16 fileNameLength;
    uint16 extraFieldLength;
    uint16 fileCommentLength;
    uint16 diskNumberWhereFileStarts;
    uint16 internalFileAttributes;
    uint32 externalFileAttributes;
    uint32 relativeOffsetOfLocalFileHeader;
};

struct zip_file_header {
    uint32 localFileHeaderSignature;
    uint16 versionNeededToExtract;
    uint16 generalPurposeBitFlag;
    uint16 compressionMethod;
    uint16 fileLastModificationTime;
    uint16 fileLastModificationDate;
    uint32 CRC32;
    uint32 compressedSize;
    uint32 uncompressedSize;
    uint16 fileNameLength;
    uint16 extraFieldLength;
};

@implementation pinch

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

/* ----------------------------------------------------------------------
       ___    __      __   _____ __    _ 
      / _/__ / /_____/ /  / __(_) /__ (_)
     / _/ -_) __/ __/ _ \/ _// / / -_)   
    /_/ \__/\__/\__/_//_/_/ /_/_/\__(_)  
                                         
 */

- (void)fetchFile:(zipentry*)entry completionBlock:(pinch_file_completion)completionBlock;
{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:entry.url]];
    
    entry.data = nil;

    int length = sizeof(struct zip_file_header) + entry.sizeCompressed + entry.filenameLength + entry.extraFieldLength;
    
    // Download '16' extra bytes as I've seen that extraFieldLength sometimes differs 
    // from the centralDirectory and the fileEntry header...
    [request addRequestHeader:@"Range" 
                        value:[NSString stringWithFormat:@"bytes=%d-%d", entry.offset, entry.offset+length+16]];
    
    [request setCompletionBlock:^(void) {
        
        unsigned char *cptr = (unsigned char*)[[request responseData] bytes];
        int len = [[request responseData] length];
        NSLog(@"## fetchFile: ended ##");
        NSLog(@"Received: %d", len);
        struct zip_file_header file_record;
        int idx = 0;

// Extract fields with a macro, if we would need to swap byteorder this would be the place
#define GETFIELD( _field ) \
memcpy(&file_record._field, &cptr[idx], sizeof(file_record._field)); \
idx += sizeof(file_record._field)
        GETFIELD( localFileHeaderSignature );
        GETFIELD( versionNeededToExtract );
        GETFIELD( generalPurposeBitFlag );
        GETFIELD( compressionMethod );
        GETFIELD( fileLastModificationTime );
        GETFIELD( fileLastModificationDate );
        GETFIELD( CRC32 );
        GETFIELD( compressedSize );
        GETFIELD( uncompressedSize );
        GETFIELD( fileNameLength );
        GETFIELD( extraFieldLength );
#undef GETFIELD

        if (entry.method == Z_DEFLATED) {
            z_stream zstream;
            int ret;
            
            zstream.zalloc = Z_NULL;
            zstream.zfree = Z_NULL;
            zstream.opaque = Z_NULL;
            zstream.avail_in = 0;
            zstream.next_in = Z_NULL;
            
            ret = inflateInit2(&zstream, -MAX_WBITS);
            if (ret != Z_OK)
                return;
            
            zstream.avail_in = entry.sizeCompressed;
            zstream.next_in = &cptr[idx+file_record.fileNameLength+file_record.extraFieldLength];
            
            unsigned char *ptr = malloc(entry.sizeUncompressed);
            
            zstream.avail_out = entry.sizeUncompressed;
            zstream.next_out = ptr;
            
            ret = inflate(&zstream, Z_SYNC_FLUSH);

            entry.data = [NSData dataWithBytes:ptr length:entry.sizeUncompressed];
                        
            printf("Uncompressed bytes: %d\n", zstream.avail_in);
            free(ptr);
            
            // TODO: handle inflate errors
            assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
            switch (ret) {
                case Z_NEED_DICT:
                    ret = Z_DATA_ERROR;     /* and fall through */
                case Z_DATA_ERROR:
                case Z_MEM_ERROR:
                    //inflateEnd(&zstream);
                    //return;
                    ;
            }
            
            inflateEnd(&zstream);
            
        } else if (entry.method == 0) {
            
            unsigned char *ptr = &cptr[idx+file_record.fileNameLength+file_record.extraFieldLength];
            
            entry.data = [NSData dataWithBytes:ptr length:entry.sizeUncompressed];

        } else {
            NSLog(@"### Unimplemented uncompress method: %d ###", entry.method);
        }
        
        completionBlock(entry);
        
    }];

    [request setFailedBlock:^(void) {
        NSLog(@"## fetchFile: failed ##");
        completionBlock(entry);
    }];
    
    [request startAsynchronous];
}

// Support method to parse the zip file content directory

- (void)parseCentralDirectory:(NSString*)url withOffset:(int)offset withLength:(int)length completionBlock:(pinch_directory_completion)completionBlock
{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    
    [request addRequestHeader:@"Range" value:[NSString stringWithFormat:@"bytes=%d-%d", offset, offset+length-1]];
    
    [request setCompletionBlock:^(void) {
        NSMutableArray *array = [NSMutableArray array];
        
        const char *cptr = (const char*)[[request responseData] bytes];
        int len = [[request responseData] length];
        NSLog(@"## parseCentralDirectory: ended ##");
        NSLog(@"Received: %d", len);

        // 46 ?!? That's the record length up to the filename see 
        // http://en.wikipedia.org/wiki/ZIP_(file_format)#File_headers
        
        while (len > 46) {
            struct zip_dir_record dir_record;
            int idx = 0;

// Extract fields with a macro, if we would need to swap byteorder this would be the place
#define GETFIELD( _field ) \
memcpy(&dir_record._field, &cptr[idx], sizeof(dir_record._field)); \
idx += sizeof(dir_record._field)
            GETFIELD( centralDirectoryFileHeaderSignature );
            GETFIELD( versionMadeBy );
            GETFIELD( versionNeededToExtract );
            GETFIELD( generalPurposeBitFlag );
            GETFIELD( compressionMethod );
            GETFIELD( fileLastModificationTime );
            GETFIELD( fileLastModificationDate );
            GETFIELD( CRC32 );
            GETFIELD( compressedSize );
            GETFIELD( uncompressedSize );
            GETFIELD( fileNameLength );
            GETFIELD( extraFieldLength );
            GETFIELD( fileCommentLength );
            GETFIELD( diskNumberWhereFileStarts );
            GETFIELD( internalFileAttributes );
            GETFIELD( externalFileAttributes );
            GETFIELD( relativeOffsetOfLocalFileHeader );
#undef GETFIELD
            
            NSString *filename = [[NSString alloc] initWithBytes:cptr+46 
                                                          length:dir_record.fileNameLength 
                                                        encoding:NSUTF8StringEncoding];
            zipentry *entry = [[zipentry alloc] init];
            entry.url = url;
            entry.filepath = filename;
            entry.method =dir_record.compressionMethod;
            entry.sizeCompressed = dir_record.compressedSize;
            entry.sizeUncompressed = dir_record.uncompressedSize;
            entry.offset = dir_record.relativeOffsetOfLocalFileHeader;
            entry.filenameLength = dir_record.fileNameLength;
            entry.extraFieldLength = dir_record.extraFieldLength;
            [array addObject:entry];
            [entry release];
            [filename release];
            len -= 46 + dir_record.fileNameLength + dir_record.extraFieldLength + dir_record.fileCommentLength;
            cptr += 46 + dir_record.fileNameLength + dir_record.extraFieldLength + dir_record.fileCommentLength;
        }
                
        completionBlock([NSArray arrayWithArray:array]);
            
    }];
    
    [request setFailedBlock:^(void) {
        NSLog(@"## parseCentralDirectory: failed ##");
        completionBlock(nil);
    }];
    
    [request startAsynchronous];
}

// Support method to find the zip file content directory

- (void)findCentralDirectory:(NSString*)url withFileLength:(int)length completionBlock:(pinch_directory_completion)completionBlock
{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    
    [request addRequestHeader:@"Range" value:[NSString stringWithFormat:@"bytes=%d-%d", length-4096, length-1]];
    
    [request setCompletionBlock:^(void) {
        char endOfCentralDirectorySignature[4] = {
            0x50, 0x4b, 0x05, 0x06
        };
        const char *cptr = (const char*)[[request responseData] bytes];
        int len = [[request responseData] length];
        char *found = NULL;
        
        NSLog(@"## findCentralDirectory: ended ##");
        NSLog(@"Received: %d", len);

        do {
            char *fptr = memchr(cptr, 0x50, len);

            if (!fptr) // done searching 
                break;
            
            // Use the last found directory
            if (!memcmp(endOfCentralDirectorySignature, fptr, 4)) 
                found = fptr;
            
            len = len-(fptr-cptr)-1;
            cptr = fptr+1;
        } while (1);
        
        if (!found) {
            NSLog(@"### No end-header found! ###");
        } else {
            NSLog(@"## Found end-header! ##");
            
            struct zip_end_record end_record;
            int idx = 0;
            
            // Extract fields with a macro, if we would need to swap byteorder this would be the place
#define GETFIELD( _field ) \
memcpy(&end_record._field, &found[idx], sizeof(end_record._field)); \
idx += sizeof(end_record._field)
            GETFIELD( endOfCentralDirectorySignature );
            GETFIELD( numberOfThisDisk );
            GETFIELD( diskWhereCentralDirectoryStarts );
            GETFIELD( numberOfCentralDirectoryRecordsOnThisDisk );
            GETFIELD( totalNumberOfCentralDirectoryRecords );
            GETFIELD( sizeOfCentralDirectory );
            GETFIELD( offsetOfStartOfCentralDirectory );
            GETFIELD( ZIPfileCommentLength );
#undef GETFIELD
            
            [self parseCentralDirectory:url 
                             withOffset:end_record.offsetOfStartOfCentralDirectory 
                             withLength:end_record.sizeOfCentralDirectory
                        completionBlock:completionBlock];
        }
        
    }];
    
    [request setFailedBlock:^(void) {
        NSLog(@"## findCentralDirectory: failed ##");
        completionBlock(nil);
    }];
    
    [request startAsynchronous];
}

/* ----------------------------------------------------------------------
       ___    __      __   ___  _             __                _ 
      / _/__ / /_____/ /  / _ \(_)______ ____/ /____  ______ __(_)
     / _/ -_) __/ __/ _ \/ // / / __/ -_) __/ __/ _ \/ __/ // /   
    /_/ \__/\__/\__/_//_/____/_/_/  \__/\__/\__/\___/_/  \_, (_)  
                                                        /___/     
 */

- (void)fetchDirectory:(NSString*)url completionBlock:(pinch_directory_completion)completionBlock
{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    
    [request setCompletionBlock:^(void) {
        NSLog(@"## fetchDirectory: ended ##");
        NSLog(@"%@", [request responseString]);
    }];
    
    // Only get the file size...
    [request setHeadersReceivedBlock:^(NSDictionary *headers) {
        int length = [[headers objectForKey:@"Content-Length"] intValue];
        NSLog(@"Length: %d bytes", length);
        [request clearDelegatesAndCancel];
        // Now get the table-of-content
        [self findCentralDirectory:url withFileLength:length completionBlock:completionBlock];
    }];
    
    [request setFailedBlock:^(void) {
        NSLog(@"## fetchDirectory: failed ##");
        completionBlock(nil);
    }];
    
    [request startAsynchronous];
}

@end
