//
//  Coin.m
//  Quest
//
//  Created by F on 01/05/14.
//  Copyright (c) 2014 F. All rights reserved.
//

#import "Coin.h"
#import "constants.h"

@interface Coin () {
    
    SKSpriteNode *coin;
    
}

@end

@implementation Coin

-(id) init {
    if (self = [super init]) {
        
        
    }
    return self;
}

-(void)createWithBaseImage:(NSString*)coinImage andLocation:(CGPoint)coinLoc {
    
    coin = [SKSpriteNode spriteNodeWithImageNamed:coinImage];
    [self addChild: coin];
    self.position  = coinLoc;
    self.zPosition = 51;
    self.name      = @"coin";

    self.physicsBody                 = [SKPhysicsBody bodyWithCircleOfRadius:coin.frame.size.width/2];
    self.physicsBody.dynamic         = YES;
    self.physicsBody.restitution     = 1.0;
    self.physicsBody.allowsRotation  = YES;
    self.physicsBody.categoryBitMask = coinCategory;
    
    
    
}

@end
