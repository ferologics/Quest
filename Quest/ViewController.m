//
//  ViewController.m
//  Quest
//
//  Created by F on 04/12/13.
//  Copyright (c) 2013 F. All rights reserved.
//

#import "ViewController.h"
#import "Level.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString* path          = [[NSBundle mainBundle] bundlePath];
    NSString* finalPath     = [path stringByAppendingPathComponent:@"GameData.plist"];
    NSDictionary* plistData = [NSDictionary dictionaryWithContentsOfFile:finalPath];
    
    float globalResizePad;
    float globalResizePhone;
    
    if ([plistData objectForKey:@"GlobalResizePad"] != nil) {
        globalResizePad = [[plistData objectForKey:@"GlobalResizePad"] floatValue];
    } else {
        globalResizePad = 1;
    }
    
    if ([plistData objectForKey:@"GlobalResizePhone"] != nil) {
        globalResizePhone = [[plistData objectForKey:@"GlobalResizePhone"] floatValue];
    } else {
        globalResizePhone = 1;
    }
    
    // Configure the view.
    SKView * skView       = (SKView *)self.view;
    skView.showsFPS       = YES;
    skView.showsNodeCount = YES;
    
    CGSize newSize;
    // Create and configure the scene.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        newSize = CGSizeMake(skView.bounds.size.width * globalResizePhone, skView.bounds.size.height * globalResizePhone);
    } else {
        newSize = CGSizeMake(skView.bounds.size.width * globalResizePad, skView.bounds.size.height * globalResizePad);
    }
    SKScene * scene = [Level sceneWithSize:newSize];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
