//
//  MainMenu.mm
//  TheSingingCoach
//
//  Created by Natalie and Edward on 11/6/14.
//  Copyright (c) 2014 Natalie and Edward. All rights reserved.
//
#import "MainMenu.h"
@implementation MainMenu

-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        SKSpriteNode *BG  = [SKSpriteNode spriteNodeWithImageNamed:@"MainMenuPic.png"];
        BG.anchorPoint = CGPointMake(0,0);
        BG.position = CGPointMake(0, 0);
        
        [self addChild:BG];
        
    
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint location =[ [touches anyObject] locationInNode:self];
    CGRect SelectButton = CGRectMake(77, 320-144, 232 , 35 );
    CGRect HighScoreButton = CGRectMake(79, 320-211, 230, 38);
    CGRect exitButton = CGRectMake(0, 320-86, 74  , 86);
    
    NSError *err;
    NSString *path  = [[NSBundle mainBundle] pathForResource:@"button" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:path];
    _ButtonSound = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];

    
    if (CGRectContainsPoint(SelectButton, location))
    {
        
        NSLog(@"Select song");
        SKScene * scene = [SongChooseMenu sceneWithSize:self.size];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        
        if (err)
        {
            NSLog (@"Cannot Load audio");
        }
        else
        {
            [_ButtonSound play];

            NSLog(@"ButtonClicked!");

        }

        [self.view presentScene:scene transition:[SKTransition fadeWithDuration:1.5]];
    }
    
    else if (CGRectContainsPoint(exitButton, location))
    {
        NSLog(@"EXIT GAME");
        
        if (err)
        {
            NSLog (@"Cannot Load audio");
        }
        else
        {
            [_ButtonSound play];

            NSLog(@"Exit Button Clicked!");
            
            SKScene* scene = [ExitSure sceneWithSize:self.size];
            scene.scaleMode = SKSceneScaleModeAspectFill;
            
            [self.view presentScene:scene transition:[SKTransition crossFadeWithDuration:0.2]];
            
            
        }
    }
    
    else if (CGRectContainsPoint(HighScoreButton, location))
    {
        NSLog(@"Entering HighScore");
        if (err)
        {
            NSLog(@"Cannot load audio");
        }
        else{
            [_ButtonSound play];
            
            SKScene* scene =[HighScorePage sceneWithSize:self.size];
            scene.scaleMode = SKSceneScaleModeAspectFill;
            
            [self.view presentScene:scene transition:[SKTransition fadeWithDuration:1.5f]];
        }
        
    }
}

-(void)update:(NSTimeInterval)currentTime
{
    
}

@end
