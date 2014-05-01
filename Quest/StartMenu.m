//
//  StartMenu.m
//  Quest
//
//  Created by F on 04/12/13.
//  Copyright (c) 2013 F. All rights reserved.
//

#import "StartMenu.h"
#import "Level.h"

@implementation StartMenu

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];

        myLabel.text         = @"Restarting Level!";
        myLabel.fontSize     = 30;
        myLabel.position     = CGPointMake(CGRectGetMidX(self.frame),
                                       CGRectGetMidY(self.frame));
        
        [self addChild:myLabel];
        [self performSelector:@selector(playAgain) withObject:nil afterDelay:3.0];
         
    }
    return self;
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

-(void) playAgain {
    
    SKScene* nextScene = [[Level alloc] initWithSize:self.size];
    SKTransition* fade =  [SKTransition fadeWithColor:[SKColor redColor] duration:1.5];
    [self.view presentScene:nextScene transition:fade];
    
}

@end
