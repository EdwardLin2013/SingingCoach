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
        
        _PlayerNameOverlay = [SKSpriteNode spriteNodeWithImageNamed:@"EnterPlayerName.png"];
        _PlayerNameOverlay.anchorPoint = CGPointMake(0, 0);
        _PlayerNameOverlay.position = CGPointMake(0, 0);
        
        _PNstate = 0;
        
        _userDefs = [NSUserDefaults standardUserDefaults];
        _myName = [_userDefs stringForKey:@"myname"];
        
        if (_myName == nil){
            _myName = @"not set";
            [_userDefs setObject:_myName forKey:@"myname"];
        }
        
        _PlayerNameText = [SKLabelNode labelNodeWithFontNamed:@"IowanOldStyle-Roman"];
        _PlayerNameText.text = _myName;
        _PlayerNameText.position = CGPointMake(243, 320-292);
        _PlayerNameText.fontSize = 15;
        _PlayerNameText.fontColor = [UIColor blackColor];
        _PlayerNameText.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        [self addChild:_PlayerNameText];
        
        [self setupTextField];
    
    }
    return self;
}

-(void) setupTextField
{
    _textField = [[UITextField alloc]initWithFrame:[self fieldRect]];
    _textField.backgroundColor = [UIColor clearColor];
    _textField.textColor = [UIColor blackColor];
    _textField.font = [UIFont fontWithName:@"IowanOldStyle-Roman" size:20 ];
    _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textField.autocorrectionType = UITextAutocorrectionTypeNo;
    _textField.keyboardType = UIKeyboardTypeDefault;
    _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _textField.placeholder = @"Enter player name";
    _textField.tintColor = [UIColor blackColor];
    _textField.delegate = self;
    
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > 20) ? NO : YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)theTextField
{
    [self processReturn];
    return YES;
}

-(void) processReturn
{
    [_textField resignFirstResponder];
    NSString* textValue = _textField.text;
    
    if([textValue compare:@""] != 0){
        _myName = textValue;
        _PNstate = 0;
        [_textField removeFromSuperview];
        [_PlayerNameOverlay removeFromParent];
        [_PlayerNameText removeFromParent];
        _PlayerNameText = [SKLabelNode labelNodeWithFontNamed:@"IowanOldStyle-Roman"];
        _PlayerNameText.text = _myName;
        _PlayerNameText.position = CGPointMake(243, 320-292);
        _PlayerNameText.fontSize = 15;
        _PlayerNameText.fontColor = [UIColor blackColor];
        _PlayerNameText.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        [self addChild:_PlayerNameText];
        
        [_userDefs setObject:_myName forKey:@"myname"];
    }
    
}

-(CGRect)fieldRect
{
    return CGRectMake(168, 118, 235, 26);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint location =[ [touches anyObject] locationInNode:self];
    CGRect SelectButton = CGRectMake(77, 320-144, 232 , 35 );
    CGRect HighScoreButton = CGRectMake(79, 320-211, 230, 38);
    CGRect exitButton = CGRectMake(0, 320-86, 74  , 86);
    CGRect playerNameButton = CGRectMake(86, 320-311, 50, 48);
    
    NSError *err;
    NSString *path  = [[NSBundle mainBundle] pathForResource:@"button" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:path];
    _ButtonSound = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    
    if (_PNstate == 0){
    
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
    
        else if (CGRectContainsPoint(playerNameButton, location)){
            [_ButtonSound play];
            [self addChild:_PlayerNameOverlay];
            [self.view addSubview:_textField];
            
            _PNstate = 1;
        }
    }
    else if (_PNstate == 1){
        CGRect exitPN = CGRectMake(337, 320-198, 83, 23);
        
        if (CGRectContainsPoint(exitPN, location)){
            [_ButtonSound play];
            [_textField removeFromSuperview];
            [_PlayerNameOverlay removeFromParent];
            _PNstate = 0;
        }
    }
}

-(void)update:(NSTimeInterval)currentTime
{
    
}

@end
