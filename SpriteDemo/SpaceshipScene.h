//
//  SpaceshipScene.h
//  SpriteDemo
//
//  Created by sunjianwen on 15-2-16.
//  Copyright (c) 2015年 FocusChina. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "AppDelegate.h"
#import <CoreMotion/CoreMotion.h>
#import "HelloScene.h"

@interface SpaceshipScene : SKScene<SKPhysicsContactDelegate>

@property BOOL contentCreated;

@property (strong) CMMotionManager* motionManager;

@end
