//
//  ExitSure.mm
//  TheSingingCoach
//
//  Created by Natalie and Edward on 11/6/14.
//  Copyright (c) 2014 Natalie and Edward. All rights reserved.
//
#import "ExitSure.h"
#import "MainMenu.h"

@implementation ExitSure

-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        
        _scaleW = 568/self.frame.size.width;
        _scaleH = 320/self.frame.size.height;
        
        SKSpriteNode *BG  = [SKSpriteNode spriteNodeWithImageNamed:@"exitSure.png"];
        BG.anchorPoint = CGPointMake(0,0);
        BG.position = CGPointMake(0, 0);
        
        [self addChild:BG];
        
        
        
    }
    return self;
}

-(void)update:(NSTimeInterval)currentTime
{
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSError *err;
    NSString *path  = [[NSBundle mainBundle] pathForResource:@"button" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:path];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    
    CGPoint location =[ [touches anyObject] locationInNode:self];
    CGRect yes = CGRectMake(188 * _scaleW, (320-184) * _scaleH   , 66 *_scaleW, 31 * _scaleH);
    
    CGRect no = CGRectMake(329 * _scaleW, (320-183)*_scaleH, 66 *_scaleW, 33 * _scaleH);
    
    if(CGRectContainsPoint(yes, location))
    {
        NSLog(@"Yes, Quit!");
        exit(0);
    }
    else if (CGRectContainsPoint(no, location))
    {
        SKScene *main = [MainMenu sceneWithSize:self.size];
        [_player play];
        NSLog(@"Don't Quit!");
        [self.view presentScene:main transition:[SKTransition crossFadeWithDuration:0.2]];
    }
    
    
}

@end
