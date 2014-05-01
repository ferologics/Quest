//
//  Character.h
//  Quest
//
//  Created by F on 04/12/13.
//  Copyright (c) 2013 F. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Character : SKNode

-(void)createWithDictionary: (NSDictionary*) charData;
-(void)update:(int)place;

@property (nonatomic, assign) int idealX;
@property (nonatomic, assign) int idealY;
@property (nonatomic, assign) BOOL isLeader;
@property (nonatomic, assign) BOOL followingEnabled;
@property (nonatomic, assign) float currentHealth;
@property (nonatomic, assign) float maxHealth;
@property (nonatomic, assign) BOOL hasOwnHealth;

-(void) makeLeader;
-(void) attack;
-(void) moveLeftWithPlace:(NSNumber*) place;
-(void) moveRightWithPlace:(NSNumber*) place;
-(void) moveUpWithPlace:(NSNumber*) place;
-(void) moveDownWithPlace:(NSNumber*) place;
-(void) doDamageWithAmount:(float)amount;
-(int) returnDirection;
-(void) stopMoving;
-(void) stopInFormation:(int)direction andPlaceInLine:(int)place leaderLocation:(CGPoint)location;
-(void) followInFormationWithDirection:(int)direction withPlace:(int)place andLeaderPosition:(CGPoint)location;

@end
