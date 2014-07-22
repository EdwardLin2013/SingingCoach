//
//  MainMenu.m
//  MelodyTest
//
//  Created by CrimsonLycans on 6/7/14.
//  Copyright (c) 2014 CrimsonLycans. All rights reserved.
// Testing push

#import "MainMenu.h"
#import "MyScene.h"
#import "ExitSure.h"
#import <AVFoundation/AVFoundation.h>


@implementation MainMenu

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        SKSpriteNode *BG  = [SKSpriteNode spriteNodeWithImageNamed:@"MainMenuPic.png"];
        BG.anchorPoint = CGPointMake(0,0);
        BG.position = CGPointMake(0, 0);
        
        [self addChild:BG];
        
    
}
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    CGPoint location =[ [touches anyObject] locationInNode:self];
    CGRect SelectButton = CGRectMake(77, 320-144, 232 , 35 );
    CGRect exitButton = CGRectMake(0, 320-86, 74  , 86);
    
    if (CGRectContainsPoint(SelectButton, location)){
        
        NSLog(@"Select song");
        SKScene * scene = [SongChooseMenu sceneWithSize:self.size];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        
        NSError *err;
        NSString *path  = [[NSBundle mainBundle] pathForResource:@"button" ofType:@"mp3"];
        NSURL *url = [NSURL fileURLWithPath:path];
        _ButtonSound = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        if (err){
            NSLog (@"Cannot Load audio");
        }
        else{
            [_ButtonSound play];

            NSLog(@"ButtonClicked!");

        }
        

        [self.view presentScene:scene transition:[SKTransition fadeWithDuration:1.5]];
    }
    
    else if (CGRectContainsPoint(exitButton, location))
    {
        NSLog(@"EXIT GAME");
        NSError *err;
        NSString *path  = [[NSBundle mainBundle] pathForResource:@"button" ofType:@"mp3"];
        NSURL *url = [NSURL fileURLWithPath:path];
        _ButtonSound = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        if (err){
            NSLog (@"Cannot Load audio");
        }
        else{
            [_ButtonSound play];

            NSLog(@"Exit Button Clicked!");
            
            SKScene * scene = [ExitSure sceneWithSize:self.size];
            scene.scaleMode = SKSceneScaleModeAspectFill;
            
            [self.view presentScene:scene transition:[SKTransition crossFadeWithDuration:0.2]];
            
            
        }
  
      
    }
}

-(void)update:(NSTimeInterval)currentTime{
    
}

@end
