//
//  Character.m
//  Quest
//
//  Created by F on 04/12/13.
//  Copyright (c) 2013 F. All rights reserved.
//

#import "Character.h"
#import "constants.h"

@interface Character (){
    
    SKSpriteNode* character;
    
    NSDictionary* characterData;
    
    BOOL useForCollisions;
    float collisionBodyCoversWhatPercent;
    
    unsigned char collisionBodyType;
    unsigned char speed;
    unsigned char currentDirection;
    unsigned char FPS; //range is 1-255 bu really we want this to be 1-60
    
    BOOL useFrontViewFrames;
    BOOL useRestingFrames;
    BOOL useSideViewFrames;
    BOOL useBackViewFrames;
    BOOL useFrontAttackFrames;
    BOOL useSideAttackFrames;
    BOOL useBackAttackFrames;
    
    SKAction* walkBackAction;
    SKAction* walkFrontAction;
    SKAction* walkSideAction;
    SKAction* repeatRestAction;
    SKAction* sideAttackAction;
    SKAction* backAttackAction;
    SKAction* frontAttackAction;
    
}

@end

@implementation Character


-(id) init {
    if (self = [super init]) {
        
        currentDirection = noDirection;
        
    }
    return self;
}

-(void)createWithDictionary: (NSDictionary*) charData {
    
    characterData  = [NSDictionary dictionaryWithDictionary:charData];

    character      = [SKSpriteNode spriteNodeWithImageNamed:[characterData objectForKey:@"BaseFrame"]];
    self.zPosition = 100;
    self.name      = @"character";

    self.position  = CGPointFromString([characterData objectForKey:@"StartLocation"]);
    
    [self addChild:character];
    
    speed = [[characterData objectForKey:@"Speed"] charValue];
    
    //TEXTURES....
    
    FPS = [[charData objectForKey:@"FPS"] integerValue];
    
    useFrontViewFrames   = [[charData objectForKey:@"UseFrontViewFrames"] boolValue];
    useBackViewFrames    = [[charData objectForKey:@"UseBackViewFrames"] boolValue];
    useSideViewFrames    = [[charData objectForKey:@"UseSideViewFrames"] boolValue];
    useFrontAttackFrames = [[charData objectForKey:@"UseFrontAttackFrames"] boolValue];
    useSideAttackFrames  = [[charData objectForKey:@"UseSideAttackFrames"] boolValue];
    useBackAttackFrames  = [[charData objectForKey:@"UseBackAttackFrames"] boolValue];
    useRestingFrames     = [[charData objectForKey:@"UseRestingFrames"] boolValue];
    
    if (useFrontViewFrames == YES) {
        [self setUpWalkFront];
    }
    if (useBackViewFrames == YES) {
        [self setUpWalkBack];
    }
    if (useSideViewFrames == YES) {
        [self setUpWalkSide];
    }
    if (useFrontAttackFrames == YES) {
        [self setUpAttackFront];
    }
    if (useSideAttackFrames == YES) {
        [self setUpAttackSide];
    }
    if (useBackAttackFrames == YES) {
        [self setUpAttackBack];
    }
    if (useRestingFrames == YES) {
        [self setUpRest];
    }

    _followingEnabled = [[characterData objectForKey:@"FollowingEnabled"] boolValue];
    useForCollisions  = [[characterData objectForKey:@"UseForCollisions"] boolValue];
    
    if (useForCollisions == YES) {
        [self setUpPhysics];
    }
    
    
    /*if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        
        self.xScale = .75;
        self.yScale = .75;
    }
    */
}

#pragma mark Set Up Physics

-(void) setUpPhysics {
    
    collisionBodyCoversWhatPercent = [[characterData objectForKey:@"CollisionBodyCoversWhatPercent"] floatValue];
    CGSize newSize                 = CGSizeMake(character.frame.size.width *collisionBodyCoversWhatPercent, character.frame.size.height * collisionBodyCoversWhatPercent);
    
    if ([[characterData objectForKey:@"CollisionBodyType" ] isEqualToString:@"square"]) {
        collisionBodyType = squareType;
        self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:newSize];
    }else{
        collisionBodyType = circleType;
        self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:newSize.width / 2 ];
    }
    if ([[characterData objectForKey:@"DebugBody"] boolValue]) {
        CGRect rect = CGRectMake(-( newSize.width / 2 ), -( newSize.height /2), newSize.width, newSize.height);
        [self debugPath:rect withBodyType:collisionBodyType];
    }
    
    self.physicsBody.dynamic            = YES;
    self.physicsBody.restitution        = 1.5;
    self.physicsBody.allowsRotation     = YES;

    self.physicsBody.categoryBitMask    = playerCategory;
    self.physicsBody.collisionBitMask   = wallCategory | playerCategory;
    self.physicsBody.contactTestBitMask = wallCategory | playerCategory;// separate other categories with |

    
}

-(void) debugPath: (CGRect) theRect withBodyType:(int) bodyType {
    
    SKShapeNode* pathShape = [[SKShapeNode alloc] init];
    CGPathRef thePath;
    
    if (bodyType == squareType) {
         thePath = CGPathCreateWithRect(theRect, NULL);
    } else {
        
        CGRect adjustedRect = CGRectMake(theRect.origin.x, theRect.origin.y, theRect.size.width, theRect.size.width);
        
        thePath = CGPathCreateWithEllipseInRect(adjustedRect, NULL);
    }
    
    pathShape.path        = thePath;

    pathShape.lineWidth   = 1;
    pathShape.strokeColor = [SKColor greenColor];
    pathShape.position    = CGPointMake(0, 0);
    pathShape.zPosition   = 1000;
    
    [self addChild:pathShape];
    
}

#pragma mark SetUp Rest/Walk Frames

-(void) setUpWalkFront {
    id object;
    
    SKTextureAtlas* atlas         = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"WalkFrontAtlasFile"]];
    NSArray* array                = [NSArray arrayWithArray:[characterData objectForKey:@"WalkFrontFrames"]];
    NSMutableArray* atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    for (object in array) {
        SKTexture* texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    SKAction* atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:1.0/FPS];
    walkFrontAction          = [SKAction repeatActionForever:atlasAnimation];

    
}
-(void) setUpWalkBack {
    id object;
    
    SKTextureAtlas* atlas         = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"WalkBackAtlasFile"]];
    NSArray* array                = [NSArray arrayWithArray:[characterData objectForKey:@"WalkBackFrames"]];
    NSMutableArray* atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    for (object in array) {
        SKTexture* texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    SKAction* atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:1.0/FPS];
    walkBackAction           = [SKAction repeatActionForever:atlasAnimation];

    
}
-(void) setUpWalkSide {
    id object;
    
    SKTextureAtlas* atlas         = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"WalkSideAtlasFile"]];
    NSArray* array                = [NSArray arrayWithArray:[characterData objectForKey:@"WalkSideFrames"]];
    NSMutableArray* atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    for (object in array) {
        SKTexture* texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }

    SKAction* atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:1.0/FPS];
    walkSideAction           = [SKAction repeatActionForever:atlasAnimation];

}
-(void) setUpRest {
    id object;
    
    SKTextureAtlas* atlas         = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"RestingAtlasFile"]];
    NSArray* array                = [NSArray arrayWithArray:[characterData objectForKey:@"RestingFrames"]];
    NSMutableArray* atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    for (object in array) {
        SKTexture* texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    SKAction* atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:1.0/FPS];
    SKAction* wait           = [SKAction waitForDuration:0.5];
    SKAction* sequence       = [SKAction sequence:@[atlasAnimation, wait]];
    repeatRestAction         = [SKAction repeatActionForever:sequence];

}

#pragma mark SetUp Attack Frames

-(void) setUpAttackFront {
    id object;

    SKTextureAtlas* atlas         = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"FrontAttackAtlasFile"]];
    NSArray* array                = [NSArray arrayWithArray:[characterData objectForKey:@"FrontAttackFrames"]];
    NSMutableArray* atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    for (object in array) {
        SKTexture* texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    SKAction* atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:1.0/FPS];
    
    if (useFrontViewFrames == YES) {
        SKAction* returnToWalking = [SKAction performSelector:@selector(runWalkFrontTextures) onTarget:self];
        frontAttackAction         = [SKAction sequence:@[atlasAnimation,returnToWalking]];
    } else {
    
        frontAttackAction = [SKAction repeatActionForever:atlasAnimation];
    }

}
-(void) setUpAttackSide {
    id object;
    
    SKTextureAtlas* atlas         = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"SideAttackAtlasFile"]];
    NSArray* array                = [NSArray arrayWithArray:[characterData objectForKey:@"SideAttackFrames"]];
    NSMutableArray* atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    for (object in array) {
        SKTexture* texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    SKAction* atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:1.0/FPS];
    
    if (useSideViewFrames == YES) {
        SKAction* returnToWalking = [SKAction performSelector:@selector(runWalkSideTextures) onTarget:self];
        sideAttackAction          = [SKAction sequence:@[atlasAnimation,returnToWalking]];
    } else {
        
        sideAttackAction = [SKAction repeatActionForever:atlasAnimation];
    }

    
}
-(void) setUpAttackBack {
    id object;

    SKTextureAtlas* atlas         = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"BackAttackAtlasFile"]];
    NSArray* array                = [NSArray arrayWithArray:[characterData objectForKey:@"BackAttackFrames"]];
    NSMutableArray* atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    for (object in array) {
        SKTexture* texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    SKAction* atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:1.0/FPS];
    
    if (useBackViewFrames == YES) {
        SKAction* returnToWalking = [SKAction performSelector:@selector(runWalkBackTextures) onTarget:self];
        backAttackAction          = [SKAction sequence:@[atlasAnimation,returnToWalking]];
    } else {
        
        backAttackAction = [SKAction repeatActionForever:atlasAnimation];
    }

    
}

#pragma mark Methods To Run Actions

-(void) runRestingTextures {

    if (repeatRestAction == nil) {

        [self setUpRest];
    }
    if (character.hasActions == YES) {

        [character removeAllActions];
    }

    [character runAction:repeatRestAction];
}
-(void) runWalkFrontTextures {

    if (walkFrontAction == nil) {

        [self setUpWalkFront];
    }

    if (character.hasActions == YES) {

        [character removeAllActions];
    }

    [character runAction:walkFrontAction];
}
-(void) runWalkBackTextures {

    if (walkBackAction == nil) {

        [self setUpWalkBack];
    }
    if (character.hasActions == YES) {

        [character removeAllActions];
    }

    [character runAction:walkBackAction];
}
-(void) runWalkSideTextures {

    if (walkSideAction == nil) {

        [self setUpWalkSide];
    }
    if (character.hasActions == YES) {

        [character removeAllActions];
    }

    [character runAction:walkSideAction];
}




#pragma mark Update

-(void) update {
    
    if (_followingEnabled == YES || _isLeader == YES) {
    
    switch (currentDirection) {
        case up:
            self.position = CGPointMake(self.position.x, self.position.y + speed);
            // making a line of characters
            if (self.position.x < _idealX && _isLeader == NO) {
                self.position = CGPointMake(round(self.position.x) + 1, self.position.y);
            } else if (self.position.x > _idealX && _isLeader == NO) {
                self.position = CGPointMake(round(self.position.x) - 1, self.position.y);
            }
            break;
        case down:
            self.position = CGPointMake(self.position.x, self.position.y - speed);
            // making a line of characters
            if (self.position.x < _idealX && _isLeader == NO) {
                self.position = CGPointMake(round(self.position.x) + 1, self.position.y);
            } else if (self.position.x > _idealX && _isLeader == NO) {
                self.position = CGPointMake(round(self.position.x) - 1, self.position.y);
            }
            break;
        case left:
            self.position = CGPointMake(self.position.x - speed, self.position.y);
            // making a line of characters
            if (self.position.y < _idealY && _isLeader == NO) {
                self.position = CGPointMake(self.position.x, round(self.position.y) + 1);
            } else if (self.position.y > _idealY && _isLeader == NO) {
                self.position = CGPointMake(self.position.x, round(self.position.y) - 1);
            }
            break;
        case right:
            self.position = CGPointMake(self.position.x + speed, self.position.y);
            // making a line of characters
            if (self.position.y < _idealY && _isLeader == NO) {
                self.position = CGPointMake(self.position.x, round(self.position.y) + 1);
            } else if (self.position.y > _idealY && _isLeader == NO) {
                self.position = CGPointMake(self.position.x, round(self.position.y) - 1);
            }
            break;
        case noDirection:
            // in case you want to do something for noDirection
            break;
        default:
            break;
    } // switch (currentDirection) {
        
    } // if (_followingEnabled == YES && _isLeader == YES) {
    
}

#pragma mark Handle Movement

CGFloat DegreesToRadians(CGFloat degrees)
{
    return degrees * M_PI/180;
}
CGFloat RadiansToDegrees(CGFloat radians)
{
    return radians * 180 / M_PI;
}
-(void) moveLeftWithPlace:(NSNumber*) place{
    
    if (_followingEnabled == YES || _isLeader == YES){
        
        self.zPosition = 100 - [place integerValue]; // converts NSNumber to int
        
        if (useSideViewFrames == YES) {
            
            character.zRotation = DegreesToRadians(0);
            character.xScale    = -1;// basicaly just flipps 100% the character on X axis
            [self runWalkSideTextures];
        
        } else if (useFrontViewFrames == YES) {
            
            character.zRotation = DegreesToRadians(-90);
            [self runWalkFrontTextures];
            
        } else {
        
        character.zRotation = DegreesToRadians(-90);
        
        }
        
        currentDirection = left;
    }
}

-(void) moveRightWithPlace:(NSNumber*) place{
    
    if (_followingEnabled == YES || _isLeader == YES){
        
        self.zPosition   = 100 - [place integerValue];
        character.xScale = 1;// basicaly just flipps the character on X axis

        if (useSideViewFrames == YES) {
            
            character.zRotation = DegreesToRadians(0);
            [self runWalkSideTextures];
            
        } else if (useFrontViewFrames == YES) {
            
            character.zRotation = DegreesToRadians(90);
            [self runWalkFrontTextures];
            
        } else {
            
            character.zRotation = DegreesToRadians(90);
            
        }
        
    currentDirection = right;
    }
}

-(void) moveUpWithPlace:(NSNumber*) place{
    
    if (_followingEnabled == YES || _isLeader == YES){

        self.zPosition   = 100 + [place integerValue];
        character.xScale = 1;// basicaly just flipps the character on X axis
        
        if (useBackViewFrames == YES) {
            
            character.zRotation = DegreesToRadians(0);
            [self runWalkBackTextures];
            
        } else if (useFrontViewFrames == YES) {
            
            character.zRotation = DegreesToRadians(180);
            [self runWalkFrontTextures];
            
        } else {
            
            character.zRotation = DegreesToRadians(180);
            
        }
        currentDirection = up;
    }
}

-(void) moveDownWithPlace:(NSNumber*) place{
    
    if (_followingEnabled == YES || _isLeader == YES){
        
        self.zPosition      = 100 - [place integerValue];
        character.xScale    = 1;// basicaly just flipps the character on X axis
        character.zRotation = DegreesToRadians(0);
        
        if (useFrontViewFrames == YES) {
            
            [self runWalkFrontTextures];
        }
        
    currentDirection = down;
    }
}

-(void) followInFormationWithDirection:(int)direction withPlace:(int)place andLeaderPosition:(CGPoint)location {
    
    
    if (_followingEnabled == YES){

    int paddingX = character.frame.size.width / 1.15;
    int paddingY = character.frame.size.height / 1.15;
        
        CGPoint newPosition;
        
        if (direction == up) {
            newPosition = CGPointMake(location.x , location.y - (paddingY * place));
            [self moveUpWithPlace:[NSNumber numberWithInt:place]];
        } else if (direction == down) {
            newPosition = CGPointMake(location.x , location.y + (paddingY * place));
            [self moveDownWithPlace:[NSNumber numberWithInt:place]];
        } else if (direction == left) {
            newPosition = CGPointMake(location.x + (paddingX * place), location.y);
            [self moveLeftWithPlace:[NSNumber numberWithInt:place]];
        } else if (direction == right) {
            newPosition = CGPointMake(location.x - (paddingX * place), location.y);
            [self moveRightWithPlace:[NSNumber numberWithInt:place]];
        }
    
        SKAction* moveIntoLine = [SKAction moveTo:newPosition duration:0.2f];
        [self runAction:moveIntoLine];

    }//  if (_followingEnabled == YES){
}

#pragma mark STOP moving

-(void)stopMoving {
    
    currentDirection = noDirection;
    
    [character removeAllActions];

}

-(void) stopInFormation:(int)direction andPlaceInLine:(int)place leaderLocation:(CGPoint)location{
    
        if (_followingEnabled == YES && currentDirection != noDirection) {
    
    int paddingX = character.frame.size.width / 1.35;
    int paddingY = character.frame.size.height / 1.35;
        
        CGPoint newPosition = CGPointMake(self.position.x, self.position.y);
    
    switch (direction) {
        case up:
            newPosition = CGPointMake(location.x , location.y - (paddingY * place));
            break;
        case down:
            newPosition = CGPointMake(location.x , location.y + (paddingY * place));
            break;
        case left:
            newPosition = CGPointMake(location.x + (paddingX * place), location.y);
            break;
        case right:
            newPosition = CGPointMake(location.x - (paddingX * place), location.y);
            break;
        default:
            break;
    }
    
    SKAction* stop         = [SKAction performSelector:@selector(stopMoving) onTarget:self];
    SKAction* moveIntoLine = [SKAction moveTo:newPosition duration:0.5f];
    SKAction* sequence     = [SKAction sequence:@[moveIntoLine, stop]];
    [self runAction:sequence];
    NSLog(@"x%f y%f", location.x, location.y);
        
        } //    if (_followingEnabled == YES){
}

#pragma mark LEADER stuff

-(void) makeLeader {
    
    _isLeader = YES;
    
}

-(int)returnDirection{
    
    return currentDirection;
    
}


























@end
