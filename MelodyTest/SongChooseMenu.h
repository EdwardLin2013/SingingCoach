//
//  SongChooseMenu.h
//  TheSingingCoach
//
//  Created by Natalie and Edward on 11/6/14.
//  Copyright (c) 2014 Natalie and Edward. All rights reserved.
//
#import <SpriteKit/SpriteKit.h>
#import "MainMenu.h"
#import "MyScene.h"
#import <AVFoundation/AVFoundation.h>


@interface SongChooseMenu : SKScene<UITextFieldDelegate>

{
    AVAudioPlayer*  _player;
    AVAudioPlayer*  _listen;
    
    double          _scaleH;
    double          _scaleW;
    
    int             _listenButtonChandelierState;   //state whether chandelier listen button is pressed
    SKSpriteNode*   _ChandelierListenNode;
    
    SKSpriteNode*   _customSongOvr;
    int             _cusSongState;                  //state whether customsong is pressed
    
    UITextField*    _textField;
    int             _fileNotFound;                  //state whether file is found
    SKSpriteNode*   _FileNotFound;
}


/* -----------------------------Private Methods--------------------------------- Begin */
-(CGRect)fieldRect;
-(void) processReturn;
-(void) setupTextField;
-(BOOL) textFieldShouldReturn:(UITextField *)theTextField;
/* -----------------------------Private Methods--------------------------------- End */


@end
