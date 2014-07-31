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

@interface MainMenu : SKScene
{
    AVAudioPlayer*  _ButtonSound;
}


@property (nonatomic, retain) AVAudioPlayer *ButtonSound;

@end
