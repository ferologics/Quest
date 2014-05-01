//
//  Level.m
//  Quest
//
//  Created by F on 04/12/13.
//  Copyright (c) 2013 F. All rights reserved.
//

#import "Level.h"
#import "constants.h"
#import "Character.h"
#import "StartMenu.h"

@interface Level () {
    
    UISwipeGestureRecognizer* swipeGestureLeft;
    UISwipeGestureRecognizer* swipeGestureRight;
    UISwipeGestureRecognizer* swipeGestureUp;
    UISwipeGestureRecognizer* swipeGestureDown;
    
    UITapGestureRecognizer* singleTap;
    UITapGestureRecognizer* twoFingerTap;
    UITapGestureRecognizer* threeFingerTap;
    
    UIRotationGestureRecognizer* rotationGR;
    
    int currentLevel;
    int levelBorderCausesDamageBy;
    unsigned char charactersInWorld; // can be 0 to 255
    
    SKNode* myWorld;
    Character* leader;
    
    NSArray* characterArray;
    
    BOOL gameHasBegun;
    BOOL useDelayedFollow;
    float followDelay;
    __block unsigned char place;

}
@end

@implementation Level

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        gameHasBegun      = NO;
        currentLevel      = 0;// later on we will create a singleton to hold game data that is independent of this class
        charactersInWorld = 0;
        
        [self setUpScene];
        [self performSelector:@selector(setUpCharacters) withObject:nil afterDelay:2.0];
    }
    return self;
}

#pragma mark SetUp Scene

-(void) setUpScene {
    //take care of setting up the world and bring in the property list
    
    //plist setup etc...
    NSString* path                      = [[NSBundle mainBundle] bundlePath];
    NSString* finalPath                 = [path stringByAppendingPathComponent:@"GameData.plist"];
    NSDictionary* plistData             = [NSDictionary dictionaryWithContentsOfFile:finalPath];

    //NSLog (@"The plist contains: %@", plistData);

    //dict for characters, lvls...
    NSMutableArray* levelArray          = [NSMutableArray arrayWithArray:[plistData objectForKey:@"Levels"]];
    NSDictionary* levelDict             = [NSDictionary dictionaryWithDictionary:[levelArray objectAtIndex:currentLevel]];
    characterArray                      = [NSArray arrayWithArray:[levelDict objectForKey:@"Characters"]];

    //NSLog (@"The plist contains: %@", characterArray);

    //world setup
    self.anchorPoint                    = CGPointMake(0.5, 0.5);
    myWorld                             = [SKNode node];
    [self addChild:myWorld];

    SKSpriteNode* map                   = [SKSpriteNode spriteNodeWithImageNamed:[levelDict objectForKey:@"Background"]];
    map.position                        = CGPointMake(0, 0);
    [myWorld addChild:map];

    useDelayedFollow                    = [[levelDict objectForKey:@"UseDelayedFollow"] boolValue];
    followDelay                         = [[levelDict objectForKey:@"FollowDelay"] floatValue];
    levelBorderCausesDamageBy           = [[levelDict objectForKey:@"LevelBorderCausesDamageBy"] intValue];
    
    // setUp Instructions
    
    SKNode* instructionNode = [SKNode node];
    instructionNode.name = @"instructions";
    [myWorld addChild:instructionNode];
    instructionNode.position = CGPointMake(0, 0);
    instructionNode.zPosition = 50;

    
    SKLabelNode* label1 = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    label1.text     = @"Swipe to Move, Rotate to Stop";
    label1.fontSize = 22;
    label1.position = CGPointMake(0, 50);

    SKLabelNode* label2 = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    label2.text     = @"Touch with 2 or 3 Fingers to Swap Leader";
    label2.fontSize = 22;
    label2.position = CGPointMake(0, -50);
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        
        label1.fontSize = 12;
        label2.fontSize = 12;
    }

    [instructionNode addChild:label1];
    [instructionNode addChild:label2];
    
    //setup Physics

    float schrinkage                    = [[levelDict objectForKey:@"ShrinkBackgroundBorderBy"] floatValue];

    int offsetX                         = (map.frame.size.width - (map.frame.size.width * schrinkage)) / 2;
    int offsetY                         = (map.frame.size.height - (map.frame.size.height * schrinkage)) / 2;

    CGRect mapWithSmallerRect           = CGRectMake(map.frame.origin.x + offsetX, map.frame.origin.y + offsetY, map.frame.size.width * schrinkage, map.frame.size.height * schrinkage);

    self.physicsWorld.gravity           = CGVectorMake(0.0,0.0);
    self.physicsWorld.contactDelegate   = self;

    myWorld.physicsBody                 = [SKPhysicsBody bodyWithEdgeLoopFromRect:mapWithSmallerRect];
    myWorld.physicsBody.categoryBitMask = wallCategory;
    
    if ([[levelDict objectForKey:@"DebugBoundary"] boolValue] == YES) {
        [self debugPath:mapWithSmallerRect];
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        
        map.xScale = .5;
        map.yScale = .5;
    }
}

-(void) debugPath: (CGRect) theRect {
    
    SKShapeNode* pathShape = [[SKShapeNode alloc] init];
    CGPathRef thePath      = CGPathCreateWithRect(theRect, NULL);
    pathShape.path         = thePath;

    pathShape.lineWidth    = 1;
    pathShape.strokeColor  = [SKColor greenColor];
    pathShape.position     = CGPointMake(0, 0);
    pathShape.zPosition    = 1000;
    
    [myWorld addChild:pathShape];
    
}

#pragma mark Gestures

-(void) didMoveToView:(SKView *)view {
    
    swipeGestureLeft                       = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)];
    [swipeGestureLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [view addGestureRecognizer:swipeGestureLeft];

    swipeGestureRight                      = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
    [swipeGestureRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [view addGestureRecognizer:swipeGestureRight];

    swipeGestureDown                       = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
    [swipeGestureDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [view addGestureRecognizer:swipeGestureDown];

    swipeGestureUp                         = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    [swipeGestureUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [view addGestureRecognizer:swipeGestureUp];

    singleTap                              = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapedOnce:)];
    singleTap.numberOfTapsRequired         = 1;
    singleTap.numberOfTouchesRequired      = 1;
    [view addGestureRecognizer:singleTap];

    twoFingerTap                           = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToSwithToSecond:)];
    twoFingerTap.numberOfTapsRequired      = 1;
    twoFingerTap.numberOfTouchesRequired   = 2;
    [view addGestureRecognizer:twoFingerTap];

    threeFingerTap                         = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToSwitchToThird:)];
    threeFingerTap.numberOfTapsRequired    = 1;
    threeFingerTap.numberOfTouchesRequired = 3;
    [view addGestureRecognizer:threeFingerTap];

    rotationGR                             = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    [view addGestureRecognizer:rotationGR];
    
}

-(void) handleSwipeLeft:(UISwipeGestureRecognizer*) recogniser {

    place = 0;
    
        [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
            //do something if we find character inside MyWorld
            gameHasBegun = YES;
            
            Character *character = (Character*) node; //casting the character, nie [character node] ale (Character*) node!!! -.-"
            
            if (character == leader) {
                [character moveLeftWithPlace:[NSNumber numberWithInt:0]];
            } else {
                if (useDelayedFollow == YES) {
                                [character performSelector:@selector(moveLeftWithPlace:) withObject:[NSNumber numberWithInt:place] afterDelay: place * followDelay];
                } else {
                    [character followInFormationWithDirection:left withPlace:place andLeaderPosition:leader.position];
                }
            }
            place++;
        }];
}

-(void) handleSwipeRight:(UISwipeGestureRecognizer*) recogniser {

    place = 0;
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
        //do something if we find character inside MyWorld
        gameHasBegun = YES;
        
        Character *character = (Character*) node; //casting the character, nie [character node] ale (Character*) node!!! -.-"
        
        if (character == leader) {
            [character moveRightWithPlace:[NSNumber numberWithInt:0]];
        } else {
            if (useDelayedFollow == YES) {
                [character performSelector:@selector(moveRightWithPlace:) withObject:[NSNumber numberWithInt:place] afterDelay: place * followDelay];
            } else {
                [character followInFormationWithDirection:right withPlace:place andLeaderPosition:leader.position];
            }
        }
        
        place++;
    }];
}

-(void) handleSwipeDown:(UISwipeGestureRecognizer*) recogniser {

    place = 0;

    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
        //do something if we find character inside MyWorld
        gameHasBegun = YES;

        Character *character = (Character*) node; //casting the character, nie [character node] ale (Character*) node!!! -.-"
        
        if (character == leader) {
            [character moveDownWithPlace:[NSNumber numberWithInt:0]];
        } else {
            if (useDelayedFollow == YES) {
                [character performSelector:@selector(moveDownWithPlace:) withObject:[NSNumber numberWithInt:place] afterDelay: place * followDelay];
            } else {
                [character followInFormationWithDirection:down withPlace:place andLeaderPosition:leader.position];
            }
        }
        
        place++;
    }];
}

-(void) handleSwipeUp:(UISwipeGestureRecognizer*) recogniser {

    place = 0;

    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
        //do something if we find character inside MyWorld
        gameHasBegun = YES;

        Character *character = (Character*) node; //casting the character, nie [character node] ale (Character*) node!!! -.-"
        
        if (character == leader) {
            [character moveUpWithPlace:[NSNumber numberWithInt:0]];
        } else {
            if (useDelayedFollow == YES) {
                [character performSelector:@selector(moveUpWithPlace:) withObject:[NSNumber numberWithInt:place] afterDelay: place * followDelay];
            } else {
                [character followInFormationWithDirection:up withPlace:place andLeaderPosition:leader.position];
            }
        }
        
        place++;
    }];
}

-(void) tapedOnce:(UITapGestureRecognizer*) recogniser {
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
        Character *character = (Character*) node;
        [character attack];
        
    }];
    
}

-(void) tapToSwithToSecond:(UITapGestureRecognizer*) recogniser {
    [self switchOrder:2];

}

-(void) tapToSwitchToThird:(UITapGestureRecognizer*) recogniser {
    [self switchOrder:3];
}

#pragma mark Swithing Leaders

-(void) switchOrder:(int)cycle {
    
    __block unsigned char i = 1;
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
        
        Character* character = (Character*)node;
        
        if (character != leader && i < cycle) {
            
            if (character.followingEnabled == YES) {
                
                NSLog(@"switch occuring");
                i++;
                leader.isLeader = NO;
                leader.followingEnabled = YES;
                leader = nil;
                leader = character;
                character.isLeader = YES;
                [character makeLeader];
                [myWorld insertChild:leader atIndex:0];
            }
            
        }
    }];
    
    
}

#pragma mark STOP ALL CHARACTERS

-(void) handleRotation:(UISwipeGestureRecognizer*) recogniser {
    if (recogniser.state == UIGestureRecognizerStateEnded) {
        [self stopAllCharactersAndPutIntoLine];
    }
}

-(void) stopAllCharactersAndPutIntoLine {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    __block unsigned char leaderDirection;
    place = 0;
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
        //do something if we find character inside MyWorld
        
        Character *character = (Character*) node; //casting the character, nie [character node] ale (Character*) node!!! -.-"
        
        if (character == leader) {
            
            leaderDirection = [leader returnDirection];
            [leader stopMoving];
            
        } else {
            
            [character stopInFormation:leaderDirection andPlaceInLine:place leaderLocation:leader.position];
            
        }
        
        place++;
    }];
    
}

-(void) stopAllPlayersFromCollision {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [myWorld enumerateChildNodesWithName:@"caracter" usingBlock:^(SKNode *node, BOOL *stop) {
        
        Character* character = (Character*) node;
        [character stopMoving];
        
    }];
    
}

#pragma mark Scene moved from view

-(void) willMoveFromView:(SKView *)view {
    
    NSLog(@"Scene moved from view");
    
    [view removeGestureRecognizer:swipeGestureLeft];
    [view removeGestureRecognizer:swipeGestureRight];
    [view removeGestureRecognizer:swipeGestureDown];
    [view removeGestureRecognizer:swipeGestureUp];
    [view removeGestureRecognizer:singleTap];
    [view removeGestureRecognizer:twoFingerTap];
    [view removeGestureRecognizer:threeFingerTap];
    [view removeGestureRecognizer:rotationGR];
}

-(void) fadeToDeath:(SKNode*)node {
    
    SKAction* fade     = [SKAction fadeAlphaTo:0 duration:10];
    SKAction* remove   = [SKAction performSelector:@selector(removeFromParent) onTarget:node];
    SKAction* sequence = [SKAction sequence:@[fade, remove]];
    [node runAction:sequence];
}

#pragma mark setUpCharacters

-(void) setUpCharacters {
    [self fadeToDeath:[myWorld childNodeWithName:@"instructions"]];
    leader = [Character node];
    [leader createWithDictionary: [characterArray objectAtIndex:0]];
    [leader makeLeader];
    [myWorld addChild:leader];
    
    int c = 1;
    
    while (c<[characterArray count]) {
        
        [self performSelector:@selector(createAnotherCharacter) withObject:nil afterDelay:(0.5 * c)];
        c++;
    }
    
}

-(void) createAnotherCharacter {
    
    charactersInWorld++;
    
    Character* character = [Character node];
    [character createWithDictionary:[characterArray objectAtIndex:charactersInWorld]];
    [myWorld addChild:character];
    
    character.zPosition = character.zPosition - charactersInWorld;
    
}

#pragma mark UPDATE

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    __block BOOL anyNonLeaderFoundInPlay = NO;
    __block BOOL leaderFound             = NO;
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
        //do something if we find character inside MyWorld
        
        Character *character = (Character*) node; //casting the character
       
        //update method in spritekit actually works even when paused -.-
        if (self.paused == NO) {
            
            if (character == leader) {
                
                leaderFound = YES;
                
            } else if (character.followingEnabled == YES){
                
                anyNonLeaderFoundInPlay = YES;
                
                character.idealX = leader.position.x;
                character.idealY = leader.position.y;
            }
            
            [character update:place];
        }
        
    }];
    // outside of the enumeration block, we then test for a leader or follower
    
    if (leaderFound == NO && gameHasBegun == YES) {
        
        if (anyNonLeaderFoundInPlay == YES) {
            
            NSLog(@"Leader not found, assigning new one");
            
            [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
               
                Character* character = (Character*) node;
                if (character.followingEnabled == YES) {
                    
                leader = character;
                [leader makeLeader];
                [myWorld insertChild:leader atIndex:0];
                
                }
                
            }];
        } else {
            
            NSLog(@"game over");
            gameHasBegun = NO;
            [self gameOver];
        }
    }

}

#pragma mark Contact Listener

-(void) didBeginContact: (SKPhysicsContact*) contact {
    
    SKPhysicsBody* firstBody, *secondBody;
    
    firstBody  = contact.bodyA;
    secondBody = contact.bodyB;
    
    if (firstBody.categoryBitMask == wallCategory || secondBody.categoryBitMask == wallCategory) {
        
        if (firstBody.categoryBitMask == playerCategory) {
            Character* character = (Character*) firstBody.node;
            [character doDamageWithAmount:levelBorderCausesDamageBy];
            [self stopAllPlayersFromCollision];
        } else if (secondBody.categoryBitMask == playerCategory) {
            Character* character = (Character*) secondBody.node;
            [character doDamageWithAmount:levelBorderCausesDamageBy];
        }
        
    }
    
    if (firstBody.categoryBitMask == playerCategory && secondBody.categoryBitMask == playerCategory) {
        
        Character* character  = (Character*) firstBody.node;
        Character* character2 = (Character*) secondBody.node;
        
        if (character == leader) {
            if (character2.followingEnabled == NO) {
                
                character2.followingEnabled = YES;
                [character2 followInFormationWithDirection:[leader returnDirection] withPlace:1 andLeaderPosition:leader.position];
                
            }
        } else if (character == leader) {
            if (character.followingEnabled == NO) {
                
                character.followingEnabled = YES;
                [character followInFormationWithDirection:[leader returnDirection] withPlace:1 andLeaderPosition:leader.position];
            
            }
        }
    }
        
}

#pragma mark GAME OVER MAN

-(void) gameOver {
    
    [myWorld enumerateChildNodesWithName:@"*" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    [myWorld removeFromParent];
    
    SKScene* nextScene = [[StartMenu alloc] initWithSize:self.size];
    SKTransition* fade =  [SKTransition fadeWithColor:[SKColor blackColor] duration:1.5];
    [self.view presentScene:nextScene transition:fade];
}

#pragma mark Camera Center

-(void) didSimulatePhysics {
    
    [self centerOnNode: leader];
    
}

-(void) centerOnNode: (SKNode*) node {

    CGPoint cameraPositionInScene = [node.scene convertPoint:node.position fromNode:node.parent];
    node.parent.position          = CGPointMake(node.parent.position.x - cameraPositionInScene.x, node.parent.position.y - cameraPositionInScene.y);

}

@end
