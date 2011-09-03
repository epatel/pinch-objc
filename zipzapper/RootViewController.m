//
//  RootViewController.m
//  zipzapper
//
//  Created by Edward Patel on 2011-05-29.
//  Copyright 2011 Memention AB. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

#import "pinch.h"

#import "RootViewController.h"
#import "EntryViewController.h"
#import "URLForm.h"

@implementation RootViewController

@synthesize fileurl;

- (void)viewDidLoad
{
    [super viewDidLoad];
    files = [[NSMutableArray alloc] init];
    self.fileurl = @"http://memention.com/ericjohnson-canabalt-ios-ef43b7d.zip";
    //self.filepath = @"http://peterhellberg.github.com/pinch/test.zip";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [files count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }

    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.text = [[files objectAtIndex:indexPath.row] filepath];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"size: %d", [[files objectAtIndex:indexPath.row] sizeUncompressed]];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
 */

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
    self.fileurl = nil;
}

- (void)dealloc
{
    [files release];
    [fileurl release];
    [super dealloc];
}

- (void)go
{
    [files removeAllObjects];
    [(UITableView*)self.view reloadData];
    
    // Pinch_Example: first fetch the directory
    
    pinch *p = [[pinch alloc] init];

    [p fetchDirectory:fileurl completionBlock:^(NSArray *array) {
        // We will receive an array of zipentries if all went well, array == nil if fetch failed
        [files addObjectsFromArray:array];
        [files sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[obj1 filepath] compare:[obj2 filepath]];
        }];
        [(UITableView*)self.view reloadData];
    }];

    [p release];    
}

- (void)url
{
    URLForm *urlForm = [[URLForm alloc] initWithNibName:@"URLForm" bundle:nil];
    [self.navigationController pushViewController:urlForm animated:YES];
    [urlForm release];
    urlForm.rootViewController = self;
    urlForm.textView.text = fileurl;
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    zipentry *entry = [files objectAtIndex:indexPath.row];
    
    // Pinch_Example: second, get the file you want
    
    pinch *p = [[pinch alloc] init];
    [p fetchFile:entry completionBlock:^(zipentry *entry) {
        
        // entry.data == nil if fetch failed. 
        
        NSLog(@"got entry: %@ %d", entry.filepath, entry.data.length);
        
        // Is is an audio file?
        
        if ([[entry.filepath pathExtension] isEqualToString:@"mp3"] ||
            [[entry.filepath pathExtension] isEqualToString:@"caf"]) {
            
            // Play audio file by placing file on disk and play it with MPMoviePlayerController
            
            NSString *path = [NSString stringWithFormat:@"%@/media.%@", NSTemporaryDirectory(), [entry.filepath pathExtension]];
            
            NSURL *url = [[[NSURL alloc] initFileURLWithPath:path] autorelease];
            
            [entry.data writeToURL:url atomically:NO];
            
            MPMoviePlayerController *mediaPlayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
            [mediaPlayer play];
            
        } else {
                        
            // Is it an image?
            
            UIImage *image = [[UIImage alloc] initWithData:entry.data]; 
            
            if (image) {            
                
                EntryViewController *entryViewController = [[EntryViewController alloc] initWithNibName:@"EntryViewController" bundle:nil];
                [self.navigationController pushViewController:entryViewController animated:YES];
                [entryViewController release];
                entryViewController.imageView.hidden = NO; 
                entryViewController.imageView.image = image; 
                entryViewController.title = [NSString stringWithFormat:@"%.0fx%.0f", image.size.width, image.size.height];
                [image autorelease];
            
            } else {
                
                // Well, just present it as text then...
                
                EntryViewController *entryViewController = [[EntryViewController alloc] initWithNibName:@"EntryViewController" bundle:nil];
                [self.navigationController pushViewController:entryViewController animated:YES];
                [entryViewController release];
                entryViewController.textView.hidden = NO; 
                entryViewController.textView.text = [[[NSString alloc] initWithData:entry.data
                                                                           encoding:NSUTF8StringEncoding] autorelease];                                              
            }
            
        }
        
    }];
    
    [p release];
}

@end
