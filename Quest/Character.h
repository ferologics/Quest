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
-(void)update;

@property (nonatomic, assign) int idealX;
@property (nonatomic, assign) int idealY;
@property (nonatomic, assign) BOOL isLeader;
@property (nonatomic, assign) BOOL followingEnabled;

-(void) makeLeader;
-(void) moveLeftWithPlace:(NSNumber*) place;
-(void) moveRightWithPlace:(NSNumber*) place;
-(void) moveUpWithPlace:(NSNumber*) place;
-(void) moveDownWithPlace:(NSNumber*) place;
-(int) returnDirection;
-(void) stopMoving;
-(void) stopInFormation:(int)direction andPlaceInLine:(int)place leaderLocation:(CGPoint)location;
-(void) followInFormationWithDirection:(int)direction withPlace:(int)place andLeaderPosition:(CGPoint)location;

@end
