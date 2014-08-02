//
//  MainMenu.h
//  TheSingingCoach
//
//  Created by Natalie and Edward on 11/6/14.
//  Copyright (c) 2014 Natalie and Edward. All rights reserved.
//
#import <SpriteKit/SpriteKit.h>
#import "SongChooseMenu.h"
#import <AVFoundation/AVFoundation.h>
#import "ExitSure.h"
#import "HighScorePage.h"

@interface MainMenu : SKScene<UITextFieldDelegate>

{
    AVAudioPlayer*  _ButtonSound;
    
    SKLabelNode*    _PlayerName;
    SKSpriteNode*   _PlayerNameOverlay;
    
    UITextField*    _textField;
    NSUserDefaults* _userDefs;
    
    int             _PNstate;
    SKLabelNode*    _PlayerNameText;
    NSString*       _myName;
}


@property (nonatomic, retain) AVAudioPlayer *ButtonSound;

@end
