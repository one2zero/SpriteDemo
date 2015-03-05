//
//  SpaceshipScene.m
//  SpriteDemo
//
//  Created by sunjianwen on 15-2-16.
//  Copyright (c) 2015年 FocusChina. All rights reserved.
//

#import "SpaceshipScene.h"

static inline CGPoint rwAdd(CGPoint a, CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}
static inline CGPoint rwSub(CGPoint a, CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}
static inline CGPoint rwMult(CGPoint a, float b) {
    return CGPointMake(a.x * b, a.y * b);
}
static inline float rwLength(CGPoint a) {
    return sqrtf(a.x * a.x + a.y * a.y);
}
// 让向量的长度（模）等于1
static inline CGPoint rwNormalize(CGPoint a) {
    float length = rwLength(a);
    return CGPointMake(a.x / length, a.y / length);
}



static inline CGFloat skRandf() {
    return rand() / (CGFloat) RAND_MAX;
}
static inline CGFloat skRand(CGFloat low, CGFloat high) {
    return skRandf() * (high - low) + low;
}

static const uint32_t missileCategory     =  0x1 << 0;
static const uint32_t shipCategory        =  0x1 << 1;
static const uint32_t rockCategory        =  0x1 << 2;

@implementation SpaceshipScene


-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        
        self.physicsWorld.gravity = CGVectorMake(0,0);
        self.physicsWorld.contactDelegate = self;
        
    }
    return self;
}

- (void)didMoveToView:(SKView *)view
{
    if(!self.contentCreated)
    {
        [self createSceneContents];
        self.contentCreated = YES;
        self.motionManager = [[CMMotionManager alloc] init];
        [self.motionManager startAccelerometerUpdates];
    }
}

- (void)update:(NSTimeInterval)currentTime{
    
    [self processUserMotionForUpdate:currentTime];
    
}

-(void)processUserMotionForUpdate:(NSTimeInterval)currentTime {
    //1
    SKSpriteNode* ship = (SKSpriteNode*)[self childNodeWithName:@"spaceship"];
    //2
    CMAccelerometerData* data = self.motionManager.accelerometerData;
    //3
    if (fabs(data.acceleration.x) > 0.2) {
        //4 How do you move the ship?
        [ship.physicsBody applyForce:CGVectorMake(20.0 * data.acceleration.x, 0)];
    }
}

- (void)createSceneContents
{
    self.backgroundColor = [SKColor grayColor];
    self.scaleMode = SKSceneScaleModeAspectFit;
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    
    SKSpriteNode *spaceship = [self newSpaceship];
    spaceship.name = @"spaceship";
    spaceship.position = CGPointMake(CGRectGetMidX(self.frame),0);
    [self addChild:spaceship];
    
    SKAction * makeRocks = [SKAction sequence:@ [[SKAction performSelector:@selector(addRock) onTarget:self]
                                                 ,[SKAction waitForDuration:1.0 withRange:0.15]
                                                 ]];
    [self runAction:[SKAction repeatActionForever:makeRocks]];
    
    SKEmitterNode *snow = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"Snow" ofType:@"sks"]];
    snow.position =CGPointMake(CGRectGetMidX(self.frame),CGRectGetMaxY(self.frame));
    snow.particlePositionRange =CGVectorMake(CGRectGetMaxX(self.frame),CGRectGetMaxY(self.frame));
    [self addChild:snow];
}


- (SKSpriteNode *)newSpaceship{
//    SKSpriteNode *hull= [[SKSpriteNode alloc] initWithColor:[SKColor grayColor] size:CGSizeMake(64,32)];
    
    SKSpriteNode *hull = [SKSpriteNode spriteNodeWithImageNamed:@"tank"];
//    SKAction *hover= [SKAction sequence:@[[SKAction waitForDuration:1.0],[SKAction moveByX:100 y:50.0 duration:1.0],[SKAction waitForDuration:1.0],[SKAction moveByX:-100.0 y:-50 duration:1.0]]];
    
//    [hull runAction:[SKAction repeatActionForever:hover]];
    hull.size = CGSizeMake(60, 60);
    SKNode *light1= [self newLight];
    light1.position = CGPointMake(-0.0,30.0);
    [hull addChild:light1];
    
    hull.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:hull.size.width/2];
    hull.physicsBody.dynamic = YES;
    hull.physicsBody.affectedByGravity = NO;
    hull.physicsBody.mass = 0.02;
    
    hull.physicsBody.categoryBitMask = shipCategory;
    hull.physicsBody.collisionBitMask = shipCategory | rockCategory;
    hull.physicsBody.contactTestBitMask = shipCategory | rockCategory;
                                            
    return hull;
}

- (SKNode *)newLight{
    
    SKEmitterNode *light = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"Boom" ofType:@"sks"]];
    light.xScale = 0.2;
    light.yScale = 0.2;
    SKAction *blink= [SKAction sequence:@[[SKAction fadeOutWithDuration:0.25],[SKAction fadeInWithDuration:0.25]]];
    SKAction * blinkForever = [SKAction repeatActionForever:blink];
    [light runAction:blinkForever];
        
    return light;
}



- (void)addRock
{
//    SKSpriteNode *rock = [[SKSpriteNode alloc] initWithColor:[SKColor brownColor] size:CGSizeMake(8,8)];
    SKSpriteNode *rock = [SKSpriteNode spriteNodeWithImageNamed:@"gold"];
    rock.position = CGPointMake(skRand(0, self.size.width),self.size.height);
    rock.name = @"rock";
    rock.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:rock.size];
    rock.physicsBody.usesPreciseCollisionDetection = YES;
    rock.physicsBody.dynamic = YES;
    
    rock.physicsBody.categoryBitMask = rockCategory;
    rock.physicsBody.collisionBitMask = missileCategory| shipCategory ;
    rock.physicsBody.contactTestBitMask = missileCategory| shipCategory ;
    
    SKAction * actionMove = [SKAction moveToY:0 duration:2*(rock.position.y/self.size.height)];
    SKAction * actionMoveDone = [SKAction removeFromParent];
    [rock runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
    
    [self addChild:rock];
}

-(void)didSimulatePhysics
{
    [self enumerateChildNodesWithName:@"rock" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.y < 0)
            [node removeFromParent];
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    SKNode *spaceship = [self childNodeWithName:@"spaceship"];

    
    // 1 - 选择其中的一个touch对象
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    // 2 - 初始化子弹的位置
//    SKSpriteNode *missile = [SKSpriteNode spriteNodeWithImageNamed:@"gold"];
    SKEmitterNode *missile = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"Boom" ofType:@"sks"]];
    missile.position = spaceship.position;
    missile.name = @"missile";
    missile.xScale = 0.5;
    missile.yScale = 0.5;
    missile.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(16, 16)];
    missile.physicsBody.usesPreciseCollisionDetection = YES;
    missile.physicsBody.dynamic = YES;
    
    missile.physicsBody.categoryBitMask = missileCategory;
    missile.physicsBody.collisionBitMask = missileCategory | rockCategory;
    missile.physicsBody.contactTestBitMask = missileCategory | rockCategory;
    
    // 3- 计算子弹移动的偏移量
    CGPoint offset = rwSub(location, missile.position);
    
    // 4 - 如果子弹是向后射的那就不做任何操作直接返回
    if (offset.y <= 0) return;
    
    // 5 - 好了，把子弹添加上吧，我们已经检查了两次位置了
    [self addChild:missile];
    // 6 - 获取子弹射出的方向
    CGPoint direction = rwNormalize(offset);
    
    // 7 - 让子弹射得足够远来确保它到达屏幕边缘
    CGPoint shootAmount = rwMult(direction, 1000);
    
    // 8 - 把子弹的位移加到它现在的位置上
    CGPoint realDest = rwAdd(shootAmount, missile.position);
    
    // 9 - 创建子弹发射的动作
    float velocity = 480.0/1.0;
    float realMoveDuration = self.size.width / velocity;
    SKAction * actionMove = [SKAction moveTo:realDest duration:realMoveDuration];
    SKAction * actionMoveDone = [SKAction removeFromParent];
    [missile runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody, *secondBody;
    
    NSLog(@"%@ %d   %@ %d",contact.bodyA.node.name,contact.bodyA.categoryBitMask ,contact.bodyB.node.name,contact.bodyB.categoryBitMask );
    
    if (contact.bodyA.categoryBitMask > contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
        
//        SKAction *hide = [SKAction fadeAlphaTo:0 duration:1.5];
//        SKAction *boom = [SKAction animateWithTextures:[NSArray arrayWithObjects:[SKTexture textureWithImageNamed:@"gold"],[SKTexture textureWithImageNamed:@"boom"], nil] timePerFrame:1] ;
//        SKAction * moveSequence = [SKAction sequence:@[hide, boom]];
//        [firstBody.node runAction:moveSequence completion:^{
//            [firstBody.node removeFromParent];
//        }];
    }
    if (firstBody.categoryBitMask == rockCategory && secondBody.categoryBitMask == shipCategory)
    {
//        [self attack: secondBody.node withMissile:firstBody.node];
        //石头装船
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        [self destoryAtX:firstBody.node.position.x Y:firstBody.node.position.y];
    }else if(firstBody.categoryBitMask == rockCategory && secondBody.categoryBitMask == missileCategory){
        //火箭炸石头
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        [self newBombAtX:firstBody.node.position.x Y:firstBody.node.position.y];
    }
}

- (void)didEndContact:(SKPhysicsContact *)contact{
    
}

-(void)newBombAtX:(CGFloat)x Y:(CGFloat)y
{
    SKEmitterNode *bomb=[NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"Smoke" ofType:@"sks"]];
    bomb.position = CGPointMake(x, y);
    bomb.name=@"myBomb";
    bomb.targetNode = [self scene];
    [self addChild:bomb];
    
    SKAction *hide = [SKAction fadeAlphaTo:0 duration:.5];
    [bomb runAction:hide completion:^{
        [bomb removeFromParent];
    }];
}

-(void)destoryAtX:(CGFloat)x Y:(CGFloat)y{
    SKEmitterNode *bomb=[NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"Smoke" ofType:@"sks"]];
    bomb.position = CGPointMake(x, y);
    bomb.name=@"destory";
    bomb.targetNode = [self scene];
    [self addChild:bomb];
    
    SKAction *zoom = [SKAction scaleTo:2.0 duration:0.25];
    SKAction *pause = [SKAction waitForDuration:0.5];
    SKAction *fadeAway = [SKAction fadeOutWithDuration:0.25];
    SKAction *remove = [SKAction removeFromParent];
    SKAction * moveSequence = [SKAction sequence:@[ zoom, pause, fadeAway, remove]];
    [bomb runAction:moveSequence completion:^{
        [self endGame];
    }];

}

-(void)endGame{
    HelloScene *hello = [[HelloScene alloc] initWithSize:self.view.frame.size];
    
    SKTransition *doors= [SKTransition doorsCloseVerticalWithDuration:0.5];
    [self.view presentScene:hello transition:doors];
}

@end
