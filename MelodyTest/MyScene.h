//
//  MyScene.h
//  MelodyTest
//

//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

//Testing changes

#import <SpriteKit/SpriteKit.h>
#import "SongChooseMenu.h"
#import "AudioController.h"
#import <AVFoundation/AVFoundation.h>
#import "NoteClass.h"

@interface MyScene : SKScene{
    AVAudioPlayer *_player;
    
    //For pitch app
	AudioController*    _audioController;
    NSString*           _pitch;
    UInt32              _sampleRate;
    UInt32              _framesSize;
    
    //For Song App
    int                 _statusGo;// The state whether loading has finished and whether program can start loading node.
    int                 _firstColision;// The state whether first collision with scorebar has occured
    int                 _idx; // For clash checking, idx ++ as soon as clash ends
    int                 _index; // for Loadnote, index ++ as soon as previous node left the screen
    float               _C3Ypos; // the position of C3 note
    float               _octaveLength; //the length of 1 octave in pixels
    float               _noteHeight; // the height of a note
    int                 _notesPerScreen; // the no. of notes in  a screen
    float               _scoreBarXpos; // the x position of scorebar
    int                 _octaveValue; // the value of one octave : 12
    float               _speed; //the speed (pixels/second) of the notes
    CGSize              _framesize; // self.frame.size
    NSMutableArray*     _StringInput;// the input string of notes
    NSMutableArray*     _NoteInput; // the array contaning the input NoteClass from stringinput
    NSMutableArray*     _NoteOutput; // the array containing notes that are currently rendered in the screen
    NoteClass*          _CurrentNode; //the node that is processed to come out
    NoteClass*          _FrontNode; // the first node in the note output array, that havent left the screen
    NoteClass*          _HittingNode; // the first node that havent hit the bar
    NoteClass*          _SparkledNode; // the first node that havent hit the bar and havent sparked
    SKSpriteNode*       _NoteBox;
    //detach the noteoutput from parents when it has crossed finish the scoreline
    float               _buffer; //for the bars delay
    float               _tempo;//PARAM
    float               _secPerBeat;//the number of seconds a beat have
    float               _oneBeatLength; // the length in pixel, of a beat
    
    // FOR ARROWS
    SKShapeNode*        _lineNode; //the node that will draw the pathToDraw each update
    SKSpriteNode*       _Arrow; //the arrow node
    NSMutableArray*     _paths; //the array of points to form pathToDraw
    float               _moveBy; //the speed of the tail generation
    float               _starting; //the starting location of a path generation
    float               _offset; // the offset from the middle of the arrow to to end of the arrow
    
    double              _currTime;                          // the time when the scene is just started (init)
    double              _loading;                           // number of seconds before notes are rendered to screen
    
    //For pause menu
    SKSpriteNode*       _pause; // the pause node
    SKSpriteNode*       _PauseOverlay; // the pause info overlay node
    int                 _isPausedScene; //state to indicate whether or not game is paused
    
    //For save recording
    SKSpriteNode*       _SaveRecordingOverlay; // the save recording decision overlay node
    
    //For song over
    int                 _songIsOver; //state to indicate whether or not song is over
    SKSpriteNode*       _songOver; // the node that is going to be rendered when song is over
    
    //param
    NSString*           _songName; // the song name to be played in the BG
    float               _delay; // amount of time in seconds for the song to play wrt loading time
    NSString*           _pianoName; // the name of the piano file to render
    
    int                 _checkPitch;                        //for times checking pitch


}

@property (nonatomic, strong) AVAudioPlayer* player;

-(id)initWithSize:(CGSize)size
     withSongName:(NSString*)songName
        withTempo: (float)tempoInput
        withDelay: (float)delay
        withInput: (NSMutableArray*)input
       withC3YPos: (float)C3Position
    withPianoName:(NSString*)pianoName;

- (void)startPitch;
- (void)startApp:(NSString*)pianoName;
- (void)playMusic:(NSString*)SongName withShortStartDelay:(NSTimeInterval)shortStartDelay;
- (void)MakeArrow;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event;
- (int)getNoteDistance:(NSString*)noteName;
- (void)loadNote;
- (void)unloadNote;
- (void)clashCheck;
- (void)ArrowMove;
- (void)pitchUpdate;


@end
