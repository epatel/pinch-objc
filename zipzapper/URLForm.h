//
//  MibForm.h
//  zipzapper
//
//  Created by Edward Patel on 2011-05-30.
//  Copyright 2011 Memention AB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RootViewController.h"

@interface URLForm : UIViewController {
    UITextView *textView;
    RootViewController *rootViewController;
}

@property (nonatomic, readonly) IBOutlet UITextView *textView;
@property (nonatomic, assign) RootViewController *rootViewController;

@end
