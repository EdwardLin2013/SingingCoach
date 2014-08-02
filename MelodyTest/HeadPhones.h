//
//  HeadPhones.h
//  MelodyTest
//
//  Created by CrimsonLycans on 2/8/14.
//  Copyright (c) 2014 CrimsonLycans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MyScene.h"

@interface HeadPhones : SKScene
{
    SKSpriteNode*   _headPhones;
    SKSpriteNode*   _beginOverlay;
    int             _hpState;
    int             _displayed;
    int             _yesDisplayed;
    NSString*       _songName;
    float           _tempoInput;
    float           _delay;
    NSMutableArray* _input;
    float           _C3Position;
    NSString*       _pianoName;
}

-(id)initWithSize:(CGSize)size
     withSongName:(NSString*)songName
        withTempo: (float)tempoInput
        withDelay: (float)delay
        withInput: (NSMutableArray*)input
       withC3YPos: (float)C3Position
    withPianoName:(NSString*)pianoName;


@end
