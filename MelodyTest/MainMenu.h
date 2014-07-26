//
//  MainMenu.h
//  MelodyTest
//
//  Created by CrimsonLycans on 6/7/14.
//  Copyright (c) 2014 CrimsonLycans. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "SongChooseMenu.h"
#import <AVFoundation/AVFoundation.h>


@interface MainMenu : SKScene
{
    AVAudioPlayer*  _ButtonSound;
}


@property (nonatomic, retain) AVAudioPlayer *ButtonSound;

@end
