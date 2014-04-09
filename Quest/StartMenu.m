//
//  StartMenu.m
//  Quest
//
//  Created by F on 04/12/13.
//  Copyright (c) 2013 F. All rights reserved.
//

#import "StartMenu.h"

@implementation StartMenu

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];

        myLabel.text         = @"Start Menu";
        myLabel.fontSize     = 30;
        myLabel.position     = CGPointMake(CGRectGetMidX(self.frame),
                                       CGRectGetMidY(self.frame));
        
        [self addChild:myLabel];
    }
    return self;
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
