//
//  HighScorePage.m
//  MelodyTest
//
//  Created by CrimsonLycans on 31/7/14.
//  Copyright (c) 2014 CrimsonLycans. All rights reserved.
//

#import "HighScorePage.h"

@interface HighScorePage ()

@end

@implementation HighScorePage

-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        SKSpriteNode *BG  = [SKSpriteNode spriteNodeWithImageNamed:@"SelectSong.png"];
        BG.anchorPoint = CGPointMake(0,0);
        BG.position = CGPointMake(0, 0);
        
        [self addChild:BG];
        
        [self setupScores];
        
    }
    return self;
}


-(void)setupScores
{
    SKSpriteNode *Chandelier = [SKSpriteNode spriteNodeWithImageNamed:@"Chandelier.png"];
    Chandelier.anchorPoint = CGPointMake(0,0);
    Chandelier.position =CGPointMake(95,320-109);
    [self addChild:Chandelier];
    
    NSUserDefaults* userDefs = [NSUserDefaults standardUserDefaults];
    double HSChandelier = [userDefs doubleForKey:@"highScore1"];
    SKLabelNode* scoreValueChandelier = [SKLabelNode labelNodeWithFontNamed:@"IowanOldStyle-Roman"];
    
    scoreValueChandelier.text = [NSString stringWithFormat:@"%f", HSChandelier];
    scoreValueChandelier.fontSize = 20;
    scoreValueChandelier.fontColor = [UIColor blackColor];
    scoreValueChandelier.position =CGPointMake(354, 320-107);
    scoreValueChandelier.zPosition = 1;
    [self addChild:scoreValueChandelier];
    
 
    SKSpriteNode *CustomSong = [SKSpriteNode spriteNodeWithImageNamed:@"cusSong.png"];
    CustomSong.anchorPoint = CGPointMake(0, 0);
    CustomSong.position = CGPointMake(94, 320-43);
    [self addChild:CustomSong];
    
    double HSCustomSong = [userDefs doubleForKey:@"highScore0"];
    
    SKLabelNode* scoreValueCustSong = [SKLabelNode labelNodeWithFontNamed:@"IowanOldStyle-Roman"];
    
    scoreValueCustSong.text = [NSString stringWithFormat:@"%f", HSCustomSong];
    scoreValueCustSong.fontSize = 20;
    scoreValueCustSong.fontColor = [UIColor blackColor];
    scoreValueCustSong.position = CGPointMake(354, 320-40);
    scoreValueCustSong.zPosition = 1;
    
    [self addChild:scoreValueCustSong];
    
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{

    CGPoint location =[ [touches anyObject] locationInNode:self];
    NSError* err;
    NSString* path  = [[NSBundle mainBundle] pathForResource:@"button" ofType:@"mp3"];
    NSURL* url = [NSURL fileURLWithPath:path];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    
    CGRect exitButton = CGRectMake(0, 320-86, 74 , 86);
    
    if (CGRectContainsPoint(exitButton, location)){
        if (err)
        {
            NSLog(@"Cannot Load audio");
        }
        else{
            [_player play];
            
            SKScene* scene = [MainMenu sceneWithSize:self.size];
            scene.scaleMode = SKSceneScaleModeAspectFill;
            
            [self.view presentScene:scene transition:[SKTransition fadeWithDuration:1.5f]];
        }
    }


    
}

- (void)update:(NSTimeInterval)currentTime
{

    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
