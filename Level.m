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
    unsigned char charactersInWorld; // can be 0 to 255
    
    SKNode* myWorld;
    Character* leader;
    
    NSArray* characterArray;
    
    BOOL useDelayedFollow;
    float followDelay;
}
@end

@implementation Level

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        currentLevel      = 0;// later on we will create a singleton to hold game data that is independent of this class
        charactersInWorld = 0;
        
        /* Setup your scene here
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        
        myLabel.text = @"Hello Level!";
        myLabel.fontSize = 30;
        myLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                       CGRectGetMidY(self.frame));
        
        [self addChild:myLabel];
        
        */
        
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
        NSLog(@"left ");
    
        __block unsigned char place = 0;
    
        [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
            //do something if we find character inside MyWorld
            
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
        NSLog(@"right ");
    __block unsigned char place = 0;
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
        //do something if we find character inside MyWorld
        
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
        NSLog(@"down ");
    __block unsigned char place = 0;
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
        //do something if we find character inside MyWorld
        
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
        NSLog(@"up ");
    __block unsigned char place = 0;
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
        //do something if we find character inside MyWorld
        
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
        NSLog(@"singleTap ");
}

-(void) tapToSwithToSecond:(UITapGestureRecognizer*) recogniser {
        NSLog(@"switched to second");
}

-(void) tapToSwitchToThird:(UITapGestureRecognizer*) recogniser {
        NSLog(@"switched to third ");
}

#pragma mark STOP ALL CHARACTERS

-(void) handleRotation:(UISwipeGestureRecognizer*) recogniser {
    if (recogniser.state == UIGestureRecognizerStateEnded) {
        
        NSLog(@"rotated");
    [self stopAllCharactersAndPutIntoLine];
    }
}

-(void) stopAllCharactersAndPutIntoLine {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    __block unsigned char leaderDirection;
    __block unsigned char place = 0;
    
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

#pragma mark setUpCharacters

-(void) setUpCharacters {
    
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
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode *node, BOOL *stop) {
        //do something if we find character inside MyWorld
        
        Character *character = (Character*) node; //casting the character
       
        //update method in spritekit actually works even when paused -.-
        if (self.paused == NO) {
            
            if (character == leader) {
                
                //do something
                
            } else if (character.followingEnabled == YES){
                
                character.idealX = leader.position.x;
                character.idealY = leader.position.y;
            }
            
            [character update];
        }
        
    }];

}

#pragma mark Contact Listener

-(void) didBeginContact: (SKPhysicsContact*) contact {
    
    SKPhysicsBody* firstBody, *secondBody;
    
    firstBody  = contact.bodyA;
    secondBody = contact.bodyB;
    
    if (firstBody.categoryBitMask == wallCategory || secondBody.categoryBitMask == wallCategory) {
        NSLog(@"HEYY someone hit the wall");
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

#pragma mark Camera Center

-(void) didSimulatePhysics {
    
    [self centerOnNode: leader];
    
}

-(void) centerOnNode: (SKNode*) node {

    CGPoint cameraPositionInScene = [node.scene convertPoint:node.position fromNode:node.parent];
    node.parent.position          = CGPointMake(node.parent.position.x - cameraPositionInScene.x, node.parent.position.y - cameraPositionInScene.y);

}

@end
