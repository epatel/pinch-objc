//
//  RootViewController.h
//  zipzapper
//
//  Created by Edward Patel on 2011-05-29.
//  Copyright 2011 Memention AB. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RootViewController : UITableViewController <UIWebViewDelegate> {
    NSString *fileurl;
    NSMutableArray *files;
}

@property (nonatomic, copy) NSString *fileurl;

- (void)go;
- (void)url;

@end
