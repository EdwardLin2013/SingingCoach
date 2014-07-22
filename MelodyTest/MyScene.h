//
//  MyScene.h
//  MelodyTest
//

//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "SongChooseMenu.h"
#import "AudioController.h"
#import <AVFoundation/AVFoundation.h>
#import "NoteClass.h"

@interface MyScene : SKScene{
    AVAudioPlayer *_player;
    
    //For pitch app
	AudioController*    _audioController;
    BufferManager*      _bufferManager;
    Float32*            _l_fftData;
    Float32*            _l_cepstrumData;
    Float32*            _l_fftcepstrumData;
    UInt32              _Hz120;
    UInt32              _Hz530;
    Float32             _maxAmp;
    int                 _bin;
    Float32             _curAmp;
    Float32             _frequency;
    Float32             _midiNum;
    NSString*           _pitch;
    UInt32              _sampleRate;
    UInt32              _framesSize;
    
    int statusGo;
    int firstColision;
    int idx; // For clash
    int index; // for Loadnote
    float C3Ypos; // PARAM
    float octaveLength;
    float noteHeight;
    int notesPerScreen;
    float scoreBarXpos;
    int octaveValue;
    float speed;
    CGSize framesize;
    NSMutableArray *StringInput;//PARAM
    NSMutableArray *NoteInput;
    NSMutableArray *NoteOutput;
    NoteClass *CurrentNode; //the node that is processed to come out
    NoteClass *FrontNode; // the first node in the array
    NoteClass *HittingNode; // the first node that havent hit the bar
    NoteClass *SparkledNode; // the first node that havent hit the bar and havent sparked
    SKSpriteNode *NoteBox;
    //detach the noteoutput from parents when it has crossed finish the scoreline ^^
    float buffer; //for the bars delay
    float tempo;//PARAM
    float secPerBeat;
    float oneBeatLength;
    
    // FOR ARROWS
    CGMutablePathRef pathToDraw;
    SKShapeNode *lineNode;
    SKSpriteNode *Arrow;
    NSMutableArray *paths;
    float moveBy;
    float starting;
    float offset;
    
    double currTime;
    double loading; //PARAM
    
    //For pause menu
    SKSpriteNode *pause;
    SKSpriteNode *PauseOverlay;
    int isPausedScene;
    
    //For over song
    int songIsOver;
    SKSpriteNode *songOver;
    
    double scaleW;
    double scaleH;
    
    //param
    NSString *_songName;
    float _delay;
    NSString *_pianoName;
    
    int checkPitch; //for times checking pitch


}

@property (nonatomic, strong) AVAudioPlayer* player;
-(id)initWithSize:(CGSize)size
     withSongName:(NSString*)songName
        withTempo: (float)tempoInput
        withDelay: (float)delay
        withInput: (NSMutableArray*)input
       withC3YPos: (float)C3Position
    withPianoName:(NSString*)pianoName;
@end
