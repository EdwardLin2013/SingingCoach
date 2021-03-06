//
//  MyScene.mm
//  TheSingingCoach
//
//  Created by Natalie and Edward on 11/6/14.
//  Copyright (c) 2014 Natalie and Edward. All rights reserved.
//
#import "MyScene.h"

//Tasks: Score calculation & highscore storing using NSUserDefault
@implementation MyScene

-(id)initWithSize:(CGSize)size
     withSongName:(NSString*)songName
        withTempo: (float)tempoInput
        withDelay: (float)delay
        withInput: (NSMutableArray*)input
       withC3YPos: (float)C3Position
    withPianoName:(NSString*)pianoName
       withLyrics:(NSString *)lyricsName
withLyricsDuration:(float)lyricsDuration
{
    if (self = [super initWithSize:size])
    {
        

        //Set Global variables based on input
        _C3Ypos = C3Position;
        _songName = songName;
        _delay = delay;
        _pianoName = pianoName;
        _tempo = tempoInput;
        _LyricsName = lyricsName;
        _lyricsDuration = lyricsDuration;
        _framesize = self.size;
        _currTime = CACurrentMediaTime();
        
        self.backgroundColor = [SKColor whiteColor];
        
        //Setup initial variables
        [self startApp:pianoName];
        [self startPitch];
        
        //Calculating delay time based on tempo and delay of the song
        float distanceToGo = _framesize.width - _scoreBarXpos;
        float timeToReach = distanceToGo / _speed;
        double totalDelayTime = (double)(_loading + timeToReach - delay);
        
        //Condition to check if the intro is too long, add loading time
        if(totalDelayTime < 0)
        {
            _loading = _loading - totalDelayTime;
            totalDelayTime = 0;
        }
        
        NSUserDefaults* userDefs = [NSUserDefaults standardUserDefaults];
        NSInteger songType = [userDefs integerForKey:@"songType"];
        
        if(songType == 0){
            [self playMusicCustom:songName withShortStartDelay:totalDelayTime];
        }
        else{
            [self playMusic:songName withShortStartDelay:totalDelayTime];

        }
        

        [self MakeArrow];
        
        _StringInput = input;
        
        
        //Lexing the string input to noteOutput and noteInput and making noteClass objects
        for (int i = 0; i< _StringInput.count; i++)
        {
            //get the note
            NSString *_note = [_StringInput objectAtIndex:i];
            //split by space
            NSArray *_notes = [_note componentsSeparatedByString:@" "];
            //get the length
            if (_notes.count < 2)
                NSLog(@"Invalid input format");
            else
            {
                NSString *_length = [_notes objectAtIndex:0];
                float lth = [_length floatValue];
                //get the pitch and noteDistance
                _note = [_notes objectAtIndex:1];
                
                int noteDistance = [self getNoteDistance:_note];
                //CALCULATE ypos from c3
                float yPos = _C3Ypos + 13* noteDistance + 1;
                
                //Make noteInput arrays
                if([_note compare:@"rest"])
                {
                    _songLength = _songLength + (double)lth;
                    SKSpriteNode *noteBox = [_NoteBox copy];
                    noteBox.anchorPoint = CGPointMake(0, 0);
                    noteBox.position = CGPointMake(_framesize.width - lth, yPos);
                    noteBox.xScale = lth;
                    float length = lth * _oneBeatLength;
                    NoteClass *n = [[NoteClass alloc]initWithNote:noteBox withPitch:_note withLength:length withLocation:yPos];
                    [_NoteInput addObject:n];
                }
                else
                {
                    SKSpriteNode *noteBox = [_NoteBox copy];
                    noteBox.anchorPoint = CGPointMake(0, 0);
                    noteBox.position = CGPointMake(_framesize.width - lth, yPos);
                    noteBox.color = [UIColor redColor];
                    noteBox.xScale = lth;
                    float length = lth * _oneBeatLength;
                    NoteClass *n = [[NoteClass alloc]initWithNote:noteBox withPitch:_note withLength:length withLocation:yPos];
                    noteBox.hidden = YES;
                    [_NoteInput addObject:n];
                }
            }
        }
        
        //Setting up FrontNode and HittingNode
        _FrontNode = [_NoteInput objectAtIndex:0];
        _HittingNode = [_NoteInput objectAtIndex:0];
        _SparkledNode = [_NoteInput objectAtIndex:0];
        printf("\n this is song Length : %f", _songLength);
        double totalTime = _secPerBeat * _songLength;
        double updateTime = totalTime * 58;
        printf("\n this is predicted totalScore: %f", updateTime);
        _predictedTotalScore = updateTime;
        
        [self setupLyrics:lyricsName withDuration:lyricsDuration];


    }
    return self;
}




//Method for pitch detector initialization
-(void)startPitch
{
    _sampleRate = 44100;
    _framesSize = 4096;
    
    _audioController = [[AudioController alloc] init:_sampleRate FrameSize:_framesSize OverLap:0.5];
    [_audioController startIOUnit];
    [_audioController startRecording];
}


//Method for Song Player initialization
-(void)startApp:(NSString*)pianoName
{
    _scoreUpdate = 1;
    
    _predictedTotalScore = 0;
    _songLength = 0;
    _currentScore = 0;
    _myScore=0;
    _totalCurrentscore=0;
    
    _totalscore = 0;
    
    _SparkleIdx = 1;
    _songIsOver = 0; //Exit or replay state
    _isPausedScene = 0; //Paused or not state
    
    _statusGo = 0; //The state of whether loading time is over or not
    _loading  = 2; // seconds to wait before everything is loaded
    
    _firstColision = 0; //TO calculate amount of first collision
    
    //Load the noteBar
    _NoteBox = [SKSpriteNode spriteNodeWithImageNamed:@"1beat.png"];
    _oneBeatLength = _NoteBox.frame.size.width;
    
    
    _index = 0; //For loading note, to indicate which note is going to be rendered after the other left the right side of the screen
    _idx = 1; //for ClashCheck, noteInput is never changed, just the index is increased by one to indicate
    //the first note that is going to hit the bar
    
    _buffer  = 3; //The amount of pixel each note is rendered towards the left, to overcome the slight delay of update
    _NoteInput = [[NSMutableArray alloc]init]; //The input note from string to the array and going to be rendered
    _NoteOutput = [[NSMutableArray alloc]init]; //The output array note that is going to be removed from screen
    
    _secPerBeat = 60.0/_tempo;
    
    //Calculating speed : if length of note is x, it has to move x distance in secPerbeat if x is 1 beat.
    _speed = _oneBeatLength/_secPerBeat;
    
    _octaveValue = 12;
    _notesPerScreen = 25;
    _noteHeight = self.frame.size.height/ _notesPerScreen;
    _octaveLength = _octaveValue * _noteHeight;
    
    //Scorebar is position at the third left of the screen
    _scoreBarXpos = self.frame.size.width/3;
    
    // Draw background (Only on devices not simulator)
    SKSpriteNode *bg= [SKSpriteNode spriteNodeWithImageNamed:@"bg.png"];
    bg.anchorPoint = CGPointMake(0,0);
    bg.position = CGPointMake(0,0);
    [self addChild:bg];
    
    //Draw ScoreBar
    SKSpriteNode *ScoreBar = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreLine.png"];
    ScoreBar.zPosition = 1;
    ScoreBar.xScale = 1;
    ScoreBar.yScale = 1.07;
    ScoreBar.name = @"BAR";
    ScoreBar.position = CGPointMake(_scoreBarXpos, CGRectGetMidY(self.frame));
    [self addChild:ScoreBar];
    
    //Draw Piano Roll
    SKSpriteNode *pianoRoll = [SKSpriteNode spriteNodeWithImageNamed:pianoName];
    pianoRoll.zPosition = 1;
    pianoRoll.position = CGPointMake(_scoreBarXpos-pianoRoll.self.frame.size.width/2, CGRectGetMidY(self.frame));
    pianoRoll.name = @"PIANO";
    [self addChild:pianoRoll];
    
    //Draw pause Button
    _pause = [SKSpriteNode spriteNodeWithImageNamed:@"Pause.png"];
    _pause.zPosition = 3;
    _pause.anchorPoint = CGPointMake(0, 0);
    _pause.position = CGPointMake(568-18,3);
    _pause.xScale = 0.5;
    _pause.yScale = 0.5;
    [self addChild:_pause];
    
    //Draw pauseword
    SKSpriteNode *pauseword = [SKSpriteNode spriteNodeWithImageNamed:@"pauseWord.png"];
    pauseword.zPosition = 6;
    pauseword.anchorPoint = CGPointMake(0, 0);
    pauseword.xScale = 0.4;
    pauseword.yScale = 0.5;
    pauseword.position = CGPointMake(568-20.5, 31);
    [self addChild:pauseword];
    
    //Make pause overlay
    _PauseOverlay = [SKSpriteNode spriteNodeWithImageNamed:@"PauseOverlay.png"];
    _PauseOverlay.anchorPoint = CGPointMake(0, 0);
    _PauseOverlay.position = CGPointMake(0, 0);
    _PauseOverlay.zPosition = 5;
    
    //Make saveRecord overlay
    _SaveRecordingOverlay = [SKSpriteNode spriteNodeWithImageNamed:@"SaveRecording.png"];
    _SaveRecordingOverlay.anchorPoint = CGPointMake(0, 0);
    _SaveRecordingOverlay.position = CGPointMake(0, 0);
    _SaveRecordingOverlay.zPosition = 10;
    
    //Make gameover overlay
    _songOver = [SKSpriteNode spriteNodeWithImageNamed:@"gameover.png"];
    _songOver.anchorPoint = CGPointMake(0, 0);
    _songOver.position = CGPointMake(0, 0);
    _songOver.zPosition = 10;
    
    //Make scoring
    _scoreValue = [SKLabelNode labelNodeWithFontNamed:@"IowanOldStyle-Bold"];
    _scoreValue.text = [NSString stringWithFormat:@"Current Score: 0.00000"];
    _scoreValue.fontSize = 10;
    _scoreValue.fontColor = [UIColor blackColor];
    _scoreValue.position = CGPointMake(_framesize.width/2 , 320-10);
    _scoreValue.zPosition = 11;
    [self addChild:_scoreValue];

}

//Method to setup musicPlayer
-(void)playMusic:(NSString*)SongName
withShortStartDelay:(NSTimeInterval)shortStartDelay
{
    NSError *err;
    NSString *path  = [[NSBundle mainBundle] pathForResource:SongName ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:path];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    if (err)
        NSLog (@"Cannot Load audio");
    else
    {
        NSLog(@"succeed!");
        _songPlayStartTime = _currTime + shortStartDelay;
        [_player playAtTime:_currTime + shortStartDelay];
    }
}

-(void)playMusicCustom:(NSString*)SongName
withShortStartDelay:(NSTimeInterval)shortStartDelay
{
    
    NSError *err;
    NSArray* dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString* docsDir = [dirPaths[0] stringByAppendingString:@"/"];
    NSString* filePath = [[docsDir stringByAppendingString:SongName] stringByAppendingString:@".mp3"];

      NSURL *url = [NSURL fileURLWithPath:filePath];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    if (err)
        NSLog (@"Cannot Load audio");
    else
    {
        NSLog(@"succeed!");
        _songPlayStartTime = _currTime + shortStartDelay;
        [_player playAtTime:_currTime + shortStartDelay];
    }
}

//Method to initialize Arrow
-(void)MakeArrow
{
    SKNode *Piano = [self childNodeWithName:@"PIANO"];
    _moveBy = -1.0; //Can be editable, -1.0 means move 1 pixel to the left each time
    
    _paths = [[NSMutableArray alloc]init];
    
    _Arrow = [SKSpriteNode spriteNodeWithImageNamed:@"arrow2.png"];
    
    //offset is the distance from arrow middle to the end of the arrow, value is fixed
    _offset = 13;
    
    _starting = Piano.frame.origin.x - _offset;
    _Arrow.position = CGPointMake(_starting, 200);
    _Arrow.xScale = 0.3;
    _Arrow.yScale = 0.3;
    _Arrow.zPosition = 2;
    _Arrow.name = @"ARROW";
    [self addChild:_Arrow];
    
    //Setting up tail path
    CGMutablePathRef _pathToDraw = CGPathCreateMutable();
    CGPathMoveToPoint(_pathToDraw, NULL, _starting, 200);
    _lineNode = [SKShapeNode node];
    _lineNode.path = _pathToDraw;
    _lineNode.strokeColor = [SKColor blackColor];
    _lineNode.lineWidth = 0.5;
    _lineNode.zPosition = 2;
    [self addChild:_lineNode];
    
    CGPathRelease(_pathToDraw);
}

//Method to determine what happens if touch begins
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint location =[ [touches anyObject] locationInNode:self];
    
    CGRect resume = CGRectMake(173, 320-184, 90, 28);
    CGRect exit  = CGRectMake(311, 320-184, 90, 28);
    CGRect pauseButton = CGRectMake(568-15-3, 3, 15, 30);
    
    if (_songIsOver == 0)
    {
        if (CGRectContainsPoint(pauseButton, location))
        {
            if (_statusGo == 1 && (CACurrentMediaTime() > _songPlayStartTime))
            {
            //Do this instead of pausing right away is to give time for the pauseOverlay to appear on the screen
            [self addChild:_PauseOverlay];
            _isPausedScene= 1;
            _pauseTime = CACurrentMediaTime();
            NSLog(@"Pausing song");
            }
        }
        else if (self.view.isPaused)
        {
            if (CGRectContainsPoint(resume, location) && ((CACurrentMediaTime() - _pauseTime)>1.3f))
            {
                NSLog(@"Resuming song");
               // [_scoreValue removeFromParent];
                [_PauseOverlay removeFromParent];
                [_player play];
                self.view.paused = NO;
                _isPausedScene = 0;
            }
            else if (CGRectContainsPoint(exit, location)&& ((CACurrentMediaTime() - _pauseTime)>1.3f))
            {
                NSLog(@"Exiting Song");
                self.view.paused = NO;
                _isPausedScene = 0;
                
                /* Stop the microphone and delete the tmp files */
                [_audioController stopIOUnit];                _audioController = NULL;
                [_audioController removeTmpFiles];
                
                [_StringInput removeAllObjects];
                [_NoteInput removeAllObjects];
                [_NoteOutput removeAllObjects];
                [_paths removeAllObjects];
                
                SKScene *songChoose = [SongChooseMenu sceneWithSize:self.size];
                songChoose.scaleMode = SKSceneScaleModeAspectFill;
                
                [self.view presentScene:songChoose transition:[SKTransition fadeWithDuration:1.5]];


            }
        }
    }
    else if (_songIsOver == 1)
    {
        CGRect SaveRecording = CGRectMake(173, 320-184, 91, 26);
        CGRect DontSaveRecording = CGRectMake(313, 320-184, 91, 26);
        
        if (CGRectContainsPoint(SaveRecording, location))
        {
            [_audioController saveRecording:_songName];
            // change the UI
            [_SaveRecordingOverlay removeFromParent];
            [self addChild:_songOver];
            _songIsOver = 2;
        }
        else if (CGRectContainsPoint(DontSaveRecording, location))
        {
            // delete the recording in the tmp directory
            [_audioController removeTmpFiles];
            // change the UI
            [_SaveRecordingOverlay removeFromParent];
            [self addChild:_songOver];
            _finishTime = CACurrentMediaTime();
            _songIsOver = 2;
            
        }
    }
    else if (_songIsOver == 3)
    {

        
        CGRect replay = CGRectMake(173, 320-184, 91, 26);
        CGRect exitSong = CGRectMake(313, 320-184, 91, 26);
        
        if (CGRectContainsPoint(replay, location) && ((CACurrentMediaTime() - _finishTime)>2.0f))
        {
            SKScene *replaySong = [[MyScene alloc]initWithSize:self.size withSongName:_songName withTempo:_tempo withDelay:_delay withInput:_StringInput withC3YPos:_C3Ypos withPianoName:_pianoName withLyrics:_LyricsName withLyricsDuration:_lyricsDuration];
            replaySong.scaleMode = SKSceneScaleModeAspectFill;
            NSLog(@"Replaying song");
            /* Stop the microphone */
            [_audioController stopIOUnit];
            _audioController = NULL;
            
            [_StringInput removeAllObjects];
            [_NoteInput removeAllObjects];
            [_NoteOutput removeAllObjects];
            [_paths removeAllObjects];


            [self.view presentScene:replaySong transition:[SKTransition crossFadeWithDuration:1.5]];
        }
        else if (CGRectContainsPoint(exitSong, location)&& ((CACurrentMediaTime() - _finishTime)>2.0f))
        {
            NSLog(@"Exiting song");
            
            /* Stop the microphone */
            [_audioController stopIOUnit];
            _audioController = NULL;
            
            [_StringInput removeAllObjects];
            [_NoteInput removeAllObjects];
            [_NoteOutput removeAllObjects];
            [_paths removeAllObjects];
            
            SKScene *songChoose = [SongChooseMenu sceneWithSize:self.size];
            songChoose.scaleMode = SKSceneScaleModeAspectFill;

            [self.view presentScene:songChoose transition:[SKTransition fadeWithDuration:1.5]];

        }
    }
}



- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    
}


//Method to calculate noteDistance based on the pitch of the note. All calculation is based on relative to C3 note,
//Hence the C3 yPosition needs to be the parameter of this class.
//All invalid note pitch format will be treated as C3 note
-(int)getNoteDistance:(NSString*)noteName
{
    int answer = 0;
    
    NSString* oct = [noteName substringFromIndex:noteName.length-1];
    NSString* newNoteName = [noteName substringToIndex:noteName.length-1];
    int difference = ((int)(oct.integerValue) - 3)*_octaveValue;
    
    if ([newNoteName compare:@"C"]==0)
    {
        answer = 0 + difference;
        return answer;
    }
    else if([newNoteName compare:@"C#"]==0 || [newNoteName compare:@"Db"] == 0)
    {
        answer = 1 + difference;
        return answer;
    }
    else if([newNoteName compare:@"D"]==0)
    {
        answer = 2 + difference;
        return answer;
    }
    else if([newNoteName compare:@"D#"]==0 || [newNoteName compare:@"Eb"] == 0)
    {
        answer = 3 + difference;
        return answer;
    }
    else if([newNoteName compare:@"E"]==0)
    {
        answer = 4 + difference;
        return answer;
    }
    else if([newNoteName compare:@"F"]==0)
    {
        answer = 5 + difference;
        return answer;
    }
    else if([newNoteName compare:@"F#"]==0 || [newNoteName compare:@"Gb"]==0)
    {
        answer = 6 + difference;
        return answer;
    }
    else if([newNoteName compare:@"G"] ==0)
    {
        answer = 7 + difference;
        return answer;
    }
    else if([newNoteName compare:@"G#"]==0 || [newNoteName compare:@"Ab"]==0)
    {
        answer = 8 + difference;
        return answer;
    }
    else if([newNoteName compare:@"A"]==0)
    {
        answer = 9 + difference;
        return answer;
    }
    else if([newNoteName compare:@"A#"]==0 || [newNoteName compare:@"Bb"]==0)
    {
        answer = 10 + difference;
        return answer;
    }
    else if([newNoteName compare:@"B"] == 0)
    {
        answer = 11 + difference;
        return answer;
    }
    
    return answer;
}



//method called by update to add and render note to the screen whenever the previous note has entirely left the screen
-(void)loadNote
{
    if (_index < _NoteInput.count)
    {
        NoteClass *toGo = [_NoteInput objectAtIndex:_index];
        SKSpriteNode *toGoNode = [toGo getNoteShape];
        
        float duration = (_framesize.width + [toGo getLength])/_speed;
        
        CGPoint point = CGPointMake(toGoNode.frame.origin.x - _buffer, toGoNode.frame.origin.y);
        toGoNode.position = point;
        
        SKAction *goLeft = [SKAction moveToX:(0 - [toGo getLength]) duration:duration];
        [toGoNode runAction:goLeft];
        _CurrentNode = toGo;
        [_NoteOutput addObject:toGo];
        
        [self addChild:toGoNode];
        _index++;
    }
    else
    {
        //Do nothing, no more note to load
    }
}

//Method called by Update to remove notes from the screen as soon as they have finished travelling the whole width of screen
-(void)unloadNote
{
    NoteClass *toRemoveNode = [_NoteOutput objectAtIndex:0];
    
    SKSpriteNode *RM = [toRemoveNode getNoteShape];
    [RM removeFromParent];
    [_NoteOutput removeObjectAtIndex:0];
    _FrontNode = [_NoteOutput objectAtIndex:0];
    
    if (_NoteOutput.count == 1)
    {
        [self addChild:_SaveRecordingOverlay];
        [_scoreValue removeFromParent];
        _songIsOver = 1;
    }


    
}



//Method that is called by Update to check clash between note and scoreBar
-(void)clashCheck
{
    NSString *pitchHitNode = [_HittingNode getPitch];
    SKSpriteNode *clash = [_HittingNode getNoteShape];
    SKNode *bar = [self childNodeWithName:@"BAR"];
    float barMax = CGRectGetMaxX(bar.frame);
    float noteMin = CGRectGetMinX(clash.frame);
    float barMin = CGRectGetMinX(bar.frame);
    float noteMax = CGRectGetMaxX(clash.frame);
    float range = [_HittingNode getyLocation];
    //float mylength = clash.frame.size.width;
    
    //hit first Half a note to score full marks
   // noteMax = noteMax - mylength /2;
    
     if (barMin > noteMin && noteMax > barMin && [pitchHitNode compare:@"rest"] != 0){
         if (_firstColision == 0){
             _firstColision = 1;
             double time = CACurrentMediaTime();
             double timeDelay = time - _currTime;
             printf("\n first collision time %f", timeDelay);
         }
         
         if (_Arrow.self.frame.origin.y <= range + 11 && _Arrow.self.frame.origin.y>=range){
             _currentScore++;
         }
         _totalCurrentscore ++;
         _totalscore++;

     }
    
     else if ((noteMax < barMin && _idx < _NoteInput.count) || ([pitchHitNode compare:@"rest"] == 0 && _idx < _NoteInput.count)){
         
         double scoreCompare = (double)_currentScore / (double)_totalCurrentscore;
         if (scoreCompare >= 0.2)
             _myScore = _myScore + _totalCurrentscore;
         else
             _myScore = _myScore + _currentScore;

         _currentScore = 0;
         _totalCurrentscore = 0;
         
         _HittingNode = [_NoteInput objectAtIndex:_idx];
         _idx++;
         
     }
     
    
    //Special effects of clashing
    
    NSString *pitchHitNodeSpark = [_SparkledNode getPitch];
    SKSpriteNode *spark = [_SparkledNode getNoteShape];
    float noteMinSpark = CGRectGetMinX(spark.frame);
    
    if(barMin < noteMinSpark && noteMinSpark < barMax && _SparkleIdx< _NoteInput.count && [pitchHitNodeSpark compare:@"rest"] != 0)
    {
 
        SKEmitterNode *explosionTwo = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"explode" ofType:@"sks"]];
        [explosionTwo setNumParticlesToEmit:35];
        explosionTwo.position = CGPointMake(_scoreBarXpos, [_SparkledNode getyLocation] + 5);
        explosionTwo.zPosition = 5;
        explosionTwo.xScale = 0.5;
        explosionTwo.yScale = 0.3;
        [self addChild:explosionTwo];
        _SparkledNode = [_NoteInput objectAtIndex:_SparkleIdx];
        if (_SparkleIdx < _NoteInput.count-1)
        {
        _SparkleIdx++;
        }
        
        
        
    }
    else if ([pitchHitNodeSpark compare:@"rest"] == 0 && _SparkleIdx < _NoteInput.count)
        
    {

        _SparkledNode = [_NoteInput objectAtIndex:_SparkleIdx];
        if (_SparkleIdx < _NoteInput.count-1)
        {
        _SparkleIdx++;
        }
    }
}



//Method called by Update to move the tail of the arrow
-(void)ArrowMove
{
    CGPoint newPt = CGPointMake(_Arrow.frame.origin.x + 5, _Arrow.frame.origin.y + (_Arrow.frame.size.height/2));
    [_paths addObject:[NSValue valueWithCGPoint:newPt]];
    
    CGMutablePathRef pathToDraw = CGPathCreateMutable();
    NSValue *startingValue = [_paths objectAtIndex:0];
    CGPoint st = startingValue.CGPointValue;
    CGPathMoveToPoint(pathToDraw, NULL, st.x, st.y);
    
    //Remove points from array as soon as it has exceeded the screen
    if (st.x < 1)
    {
        [_paths removeObjectAtIndex:0];
        startingValue = [_paths objectAtIndex:0];
        st = startingValue.CGPointValue;
        CGPathMoveToPoint(pathToDraw, NULL, st.x, st.y);
    }
    
    //Move everybody by "moveBy" pixel and render
    for (int i = 0; i<[_paths count]; i++)
    {
        NSValue *temp = [_paths objectAtIndex:i];
        CGPoint tempPt = temp.CGPointValue;
        tempPt.x = tempPt.x + _moveBy;
        [_paths replaceObjectAtIndex:i withObject:[NSValue valueWithCGPoint:tempPt]];
        
        //add all the lines to the new path
        CGPathAddLineToPoint(pathToDraw, NULL, tempPt.x, tempPt.y);
    }
    
    //make a copy of the new path and plug in to lineNode
    _lineNode.path = pathToDraw;
    CGPathRelease(pathToDraw);
}

//Method called by Update to check pitch of the input Soundwave
-(void)pitchUpdate
{
    _pitch = [_audioController CurrentPitch];
    int distance = [self getNoteDistance:_pitch];
    float yPositionforArrow  =  _C3Ypos + 13* distance + 1;
    
    if (yPositionforArrow <0)
        yPositionforArrow = 0 + 3;
    else if(yPositionforArrow > _framesize.height)
        yPositionforArrow = _framesize.height - 3;
    
    CGPoint position = CGPointMake(_starting, yPositionforArrow + 5);
    SKAction *moveToLocation = [SKAction moveTo:position duration:0.3];
    [_Arrow runAction:moveToLocation];
}


-(void)update:(CFTimeInterval)currentTime
{
    //Check if self is paused
    if (self.view.isPaused == YES)
    {
        //Do not update anything if song is paused
    }
    else if(_songIsOver == 1){
        //Do note update anything
    }
    //score calculation
    else if (_songIsOver == 2 )
    {
        double scoreEarned = (double)_myScore;
        double totalAllScore = (double)_totalscore;

        double finalScore = scoreEarned/totalAllScore * 100;
        
        printf("\n this is actualtotalscore : %f", totalAllScore);
        [_scoreValue removeFromParent];
        _scoreValue = [SKLabelNode labelNodeWithFontNamed:@"IowanOldStyle-Bold"];
        _scoreValue.fontSize = 20;
        _scoreValue.fontColor = [UIColor blackColor];
        _scoreValue.text = [NSString stringWithFormat:@"%f", finalScore];
        _scoreValue.position = CGPointMake(335, 320-135);
        _scoreValue.zPosition = 11;
        [self addChild:_scoreValue];
        
        //Saving score
        NSUserDefaults* userDefs = [NSUserDefaults standardUserDefaults];
        
        //chandelier = songType1, customSong = songType0, and etc based on order
        NSInteger songType = [userDefs integerForKey:@"songType"];
        NSString* HSstringToEnter = @"highScore";
        NSString* songTypeString = [NSString stringWithFormat:@"%d", (int)songType];
        HSstringToEnter = [HSstringToEnter stringByAppendingString:songTypeString];
        double HS = [userDefs doubleForKey:HSstringToEnter];
        
        if (finalScore > HS){
            [userDefs setDouble:finalScore forKey:HSstringToEnter];
        }
        //Saving finalScore to historylog
        NSString* fileName = [userDefs objectForKey:@"myname"];
        fileName = [fileName stringByAppendingString:@"'s score"];
        fileName = [fileName stringByAppendingString:@".txt"];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:fileName];

        if (![[NSFileManager defaultManager] fileExistsAtPath:path]){
            [[NSData data] writeToFile:path atomically:YES];
        }
        
        // append
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
        [handle truncateFileAtOffset:[handle seekToEndOfFile]];
        
        NSString *tempString = @"Score at date ";
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMdd_HHmm"];
        NSString *strNow = [dateFormatter stringFromDate:[NSDate date]];
        
        strNow = [tempString stringByAppendingString:strNow];
        NSString *songTypeTemp = @" and song number: ";
        strNow = [strNow stringByAppendingString:songTypeTemp];
        strNow = [strNow stringByAppendingString:songTypeString];
        
        songTypeTemp = @" ";
        strNow = [strNow stringByAppendingString:songTypeTemp];
        
        tempString = @" is: ";
        strNow = [strNow stringByAppendingString: tempString];
        
        NSString* myScoreToWriteToHistory = [NSString stringWithFormat:@"%f", finalScore];
        
        myScoreToWriteToHistory = [strNow stringByAppendingString:myScoreToWriteToHistory];
        myScoreToWriteToHistory = [myScoreToWriteToHistory stringByAppendingString:@"\n"];
        
        [handle writeData:[myScoreToWriteToHistory dataUsingEncoding:NSUTF8StringEncoding]];
        [handle closeFile];
        NSLog(@"Score saved.");

        _songIsOver = 3;
    }
    else if (_songIsOver == 3)
    {
        //Do nothing
    }
    else
    {
        //Check whether pausedScene state is 1 = paused button pressed
        if (_isPausedScene == 1)
        {
            [_player pause];
            self.view.paused = YES;
            
        }
        
        else{
        //Checking whether loading time has been exceeded
            if (currentTime - _currTime > _loading)
            {
                if (_statusGo == 0)
                {
                    _statusGo = 1;
                    [self loadNote];
                    [self ArrowMove];
                }
                [self ArrowMove];
            
                //Do Note Loading
                SKSpriteNode *currNode = [_CurrentNode getNoteShape];
                float location = currNode.frame.origin.x;
                float nextNode = _framesize.width - [_CurrentNode getLength];
                if (location < nextNode && _index < _NoteInput.count)
                    [self loadNote];
            
                //Do ClashCheck
                [self clashCheck];
            
                //Do Note unloading
                SKSpriteNode *frntNode = [_FrontNode getNoteShape];
                float myLocation = frntNode.frame.origin.x;
                if (myLocation <= 0 - (frntNode.self.frame.size.width) && _NoteOutput.count > 1)
                {
                    [self unloadNote];
                }
        
                //Do pitchUpdate
                [self pitchUpdate];
            
                if (_scoreUpdate %20 == 0)
                {
                    // printf("YES\n");
                    [_scoreValue removeFromParent];
                    double currentScore = (double)_myScore / (double)_predictedTotalScore * 100;
                    _scoreValue = [SKLabelNode labelNodeWithFontNamed:@"IowanOldStyle-Bold"];
                    _scoreValue.text = [NSString stringWithFormat:@"Current Score: %f", currentScore];
                    _scoreValue.fontSize = 10;
                    _scoreValue.fontColor = [UIColor blackColor];
                    _scoreValue.position = CGPointMake(_framesize.width/2 , 320-10);
                    _scoreValue.zPosition = 11;
                    [self addChild:_scoreValue];
                    _scoreUpdate = 1;
                }
                else{
                    _scoreUpdate = _scoreUpdate + 1;
                }
            }
        }
    }
}

-(void) setupLyrics:(NSString*)filename withDuration:(float)songDuration
{
    NSString *filepath = [[NSBundle mainBundle] pathForResource:filename ofType:@"txt"];
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
        NSLog(@"Error reading file: %@", error.localizedDescription);

    NSMutableArray *listArray = [NSMutableArray arrayWithArray:[fileContents componentsSeparatedByString:@"\n"]];
    
    _Text = [SKNode node];
    _Text.zPosition = 2;
    
    _lyricsoverlay= [SKSpriteNode spriteNodeWithImageNamed:@"lyricsOverlay"];
    _lyricsoverlay.anchorPoint = CGPointMake(0, 0);
    _lyricsoverlay.position = CGPointMake(564, 0);
    _lyricsoverlay.zPosition = 2;
    _lyricsoverlay.hidden = YES;
    [self addChild:_lyricsoverlay];
    
    int count = 0;
    int distance = 100;
    if (listArray.count > 26)
    {
        int leftover = (int)listArray.count - 28;
        distance = leftover * 12;
    }
    
    for (NSString* string in listArray)
    {
        
        SKLabelNode *a = [SKLabelNode labelNodeWithFontNamed:@"IowanOldStyle-Bold"];
        a.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        a.fontSize = 10;
        a.fontColor = [SKColor blackColor];
        a.position = CGPointMake(a.position.x, a.position.y - (11 * count));
        count++;
        a.text = string;
        [_Text addChild:a];
        
    }
    
    _Text.position = CGPointMake(570, 295.0);
    SKAction* moveUp = [SKAction moveByX:0 y:distance duration:songDuration];
    [_Text runAction:moveUp];
    
    _Text.hidden = YES;
    [self addChild:_Text];
    _TextState = 0;
    
}

-(void) didMoveToView: (SKView *) view
{

    _swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector( handleSwipeRight:)];
    [_swipeRightGesture setDirection: UISwipeGestureRecognizerDirectionRight];

    [view addGestureRecognizer: _swipeRightGesture ];

    _swipeLeftGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeLeft:)];
    [_swipeLeftGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
    [view addGestureRecognizer:_swipeLeftGesture];

}

- ( void ) willMoveFromView: (SKView *) view
{
    [view removeGestureRecognizer: _swipeRightGesture ];
    [view removeGestureRecognizer:_swipeLeftGesture];
    NSLog(@"Removing gesReg");

}
 

-(void) handleSwipeLeft: ( UISwipeGestureRecognizer*) recognizer
{
    if (_TextState == 0){
        SKAction *goLeft = [SKAction moveByX:-138 y:0 duration:0.5f];
        [_lyricsoverlay runAction:goLeft];
        [_Text runAction:goLeft];
        _lyricsoverlay.hidden = NO;
        _Text.hidden = NO;
        _TextState = 1;
    }

}
-(void) handleSwipeRight:( UISwipeGestureRecognizer *) recognizer
{
    
    if (_TextState == 1)
    {
        SKAction *goRight = [SKAction moveByX:138 y:0 duration:0.5f];
        [_lyricsoverlay runAction:goRight];
        [_Text runAction:goRight];
        _TextState = 0;
    }
}



@end
