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
{
    if (self = [super initWithSize:size])
    {
        

        //Set Global variables based on input
        _C3Ypos = C3Position;
        _songName = songName;
        _delay = delay;
        _pianoName = pianoName;
        _tempo = tempoInput;
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
    _totalscoreArray = [[NSMutableArray alloc]init];
    _scoreArray = [[NSMutableArray alloc]init];
    _score = 0;
    _totalscore = 0;
    _SparkleIdx = 1;
    _checkPitch = 1; //Initial value of pitch checking
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
    /*SKSpriteNode *bg= [SKSpriteNode spriteNodeWithImageNamed:@"bg.png"];
     bg.anchorPoint = CGPointMake(0,0);
     bg.position = CGPointMake(0,0);
     [self addChild:bg];*/
    
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
    
    CGRect resume = CGRectMake(173, 320-170, 90, 28);
    CGRect exit  = CGRectMake(311, 320-171, 90, 28);
    CGRect pauseButton = CGRectMake(568-15-3, 3, 15, 30);
    
    if (_songIsOver == 0)
    {
        if (CGRectContainsPoint(pauseButton, location))
        {
            //Do this instead of pausing right away is to give time for the pauseOverlay to appear on the screen
            [self addChild:_PauseOverlay];
            _isPausedScene= 1;
            
            NSLog(@"Pausing song");
        }
        else if (self.view.isPaused)
        {
            if (CGRectContainsPoint(resume, location))
            {
                NSLog(@"Resuming song");
                [_PauseOverlay removeFromParent];
                [_player play];
                self.view.paused = NO;
                _isPausedScene = 0;
            }
            else if (CGRectContainsPoint(exit, location))
            {
                NSLog(@"Exiting Song");
                self.view.paused = NO;
                _isPausedScene = 0;
                
                SKScene *songChoose = [SongChooseMenu sceneWithSize:self.size];
                songChoose.scaleMode = SKSceneScaleModeAspectFill;
                
                [self.view presentScene:songChoose transition:[SKTransition fadeWithDuration:1.5]];

                /* Stop the microphone and delete the tmp files */
                [_audioController stopIOUnit];
                [_audioController removeTmpFiles];
                
                [_StringInput removeAllObjects];
                [_NoteInput removeAllObjects];
                [_NoteOutput removeAllObjects];
                [_paths removeAllObjects];
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
            _songIsOver = 2;
            
        }
    }
    else if (_songIsOver > 1)
    {

        
        CGRect replay = CGRectMake(173, 320-184, 91, 26);
        CGRect exitSong = CGRectMake(313, 320-184, 91, 26);
        
        if (CGRectContainsPoint(replay, location))
        {
            SKScene *replaySong = [[MyScene alloc]initWithSize:self.size withSongName:_songName withTempo:_tempo withDelay:_delay withInput:_StringInput withC3YPos:_C3Ypos withPianoName:_pianoName];
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
        else if (CGRectContainsPoint(exitSong, location))
        {
            NSLog(@"Exiting song");
            SKScene *songChoose = [SongChooseMenu sceneWithSize:self.size];
            songChoose.scaleMode = SKSceneScaleModeAspectFill;
            /* Stop the microphone */
            [_audioController stopIOUnit];
            _audioController = NULL;
            
            [_StringInput removeAllObjects];
            [_NoteInput removeAllObjects];
            [_NoteOutput removeAllObjects];
            [_paths removeAllObjects];

            
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
    float mylength = clash.frame.size.width;
    
    //hit first Half a note to score full marks
    noteMax = noteMax - mylength /2;
    
     if (barMin > noteMin && noteMax > barMin && [pitchHitNode compare:@"rest"] != 0){
         if (_firstColision == 0){
             _firstColision = 1;
             double time = CACurrentMediaTime();
             double timeDelay = time - _currTime;
             printf("\n first collision time %f", timeDelay);
         }
         
         if (_Arrow.self.frame.origin.y <= range + 11 && _Arrow.self.frame.origin.y>=range){
             _score++;
         }
         _totalscore ++;

     }
    
     else if ((noteMax < barMin && _idx < _NoteInput.count) || ([pitchHitNode compare:@"rest"] == 0 && _idx < _NoteInput.count)){
         
         [_scoreArray addObject:[NSNumber numberWithInt:_score]];
         [_totalscoreArray addObject:[NSNumber numberWithInt:_totalscore]];
         
         _score = 0;
         _totalscore = 0;
         
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
    SKAction *moveToLocation = [SKAction moveTo:position duration:0.5];
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
        double scoreEarned = 0;
        double totalAllScore = 0;
        for (int i = 0; i<_scoreArray.count;i++){
            NSNumber *number = [_scoreArray objectAtIndex:i];
            NSNumber *numberTotal = [_totalscoreArray objectAtIndex:i];
            double numberDouble = [number doubleValue];
            double numberTotalDouble = [numberTotal doubleValue];
            double divisionResult = numberDouble / numberTotalDouble;
            if (divisionResult >= 0.5){
                numberDouble = numberTotalDouble;
            }
            scoreEarned = scoreEarned + numberDouble;
            totalAllScore = totalAllScore + numberTotalDouble;
        }

        double finalScore = scoreEarned/totalAllScore * 100;
        
        _scoreValue = [SKLabelNode labelNodeWithFontNamed:@"IowanOldStyle-Roman"];
        _scoreValue.text = [NSString stringWithFormat:@"%f", finalScore];
        _scoreValue.fontSize = 20;
        _scoreValue.fontColor = [UIColor blackColor];
        _scoreValue.position = CGPointMake(325, 320-135);
        _scoreValue.zPosition = 11;
        [self addChild:_scoreValue];

        
        //Saving score
        NSUserDefaults* userDefs = [NSUserDefaults standardUserDefaults];
        
        NSInteger songType = [userDefs integerForKey:@"songType"];
        NSString* HSstringToEnter = @"highScore";
        NSString* songTypeString = [NSString stringWithFormat:@"%d", (int)songType];
        HSstringToEnter = [HSstringToEnter stringByAppendingString:songTypeString];
        double HS = [userDefs doubleForKey:HSstringToEnter];
        
        if (finalScore > HS){
            [userDefs setDouble:finalScore forKey:HSstringToEnter];
        }
        
        _songIsOver = 3;
        
        
        
    }
    else if (_songIsOver == 3){
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
                [self unloadNote];
        
            //Do Pitch Detection
            if (_checkPitch%2 == 0)
            {
                [self pitchUpdate];
                _checkPitch = 1;
            }
            else
                _checkPitch ++;
        }
    }
}
@end
