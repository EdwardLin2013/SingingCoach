//
//  MyScene.m
//  NoteTest
//
//  Created by CrimsonLycans on 11/6/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
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
    withPianoName:(NSString*)pianoName{
    if (self = [super initWithSize:size]) {
        
        //Set Global variables based on input
        C3Ypos = C3Position;
        _songName = songName;
        _delay = delay;
        _pianoName = pianoName;
        tempo = tempoInput;
        framesize = self.size;
        currTime = CACurrentMediaTime();
        
        self.backgroundColor = [SKColor whiteColor];
        
        //Setup initial variables
        [self startApp:pianoName];
        [self startPitch];
        
        //Calculating delay time based on tempo and delay of the song
        float distanceToGo = framesize.width - scoreBarXpos;
        float timeToReach = distanceToGo / speed;
        double totalDelayTime = (double)(loading + timeToReach - delay);
        
        //Condition to check if the intro is too long, add loading time
        if(totalDelayTime < 0){
            loading = loading - totalDelayTime;
            totalDelayTime = 0;
        }
        
        [self playMusic:songName withShortStartDelay:totalDelayTime];
        [self MakeArrow];
        
        StringInput = input;
        
        
        //Lexing the string input to noteOutput and noteInput and making noteClass objects
        for (int i = 0; i< StringInput.count; i++){
            
            //get the note
            NSString *_note = [StringInput objectAtIndex:i];
            //split by space
            NSArray *_notes = [_note componentsSeparatedByString:@" "];
            //get the length
            if (_notes.count < 2){
                NSLog(@"Invalid input format");
            }
            else{
                NSString *_length = [_notes objectAtIndex:0];
                float lth = [_length floatValue];
                //get the pitch and noteDistance
                _note = [_notes objectAtIndex:1];
                
                int noteDistance = [self getNoteDistance:_note];
                //CALCULATE ypos from c3
                float yPos = C3Ypos + 13* noteDistance + 1;
                
                //Make noteInput arrays
                if([_note compare:@"rest"]){
                    SKSpriteNode *noteBox = [NoteBox copy];
                    noteBox.anchorPoint = CGPointMake(0, 0);
                    noteBox.position = CGPointMake(framesize.width - lth, yPos);
                    noteBox.xScale = lth;
                    float length = lth * oneBeatLength;
                    NoteClass *n = [[NoteClass alloc]initWithNote:noteBox withPitch:_note withLength:length withLocation:yPos];
                    [NoteInput addObject:n];
                }
                else{
                    SKSpriteNode *noteBox = [NoteBox copy];
                    noteBox.anchorPoint = CGPointMake(0, 0);
                    noteBox.position = CGPointMake(framesize.width - lth, yPos);
                    noteBox.color = [UIColor redColor];
                    noteBox.xScale = lth;
                    float length = lth * oneBeatLength;
                    NoteClass *n = [[NoteClass alloc]initWithNote:noteBox withPitch:_note withLength:length withLocation:yPos];
                    noteBox.hidden = YES;
                    [NoteInput addObject:n];
                }
            }
            
        }
        
        //Setting up FrontNode and HittingNode
        FrontNode = [NoteInput objectAtIndex:0];
        HittingNode = [NoteInput objectAtIndex:0];
        SparkledNode = [NoteInput objectAtIndex:0];
        
    }
    
    return self;
}


//Method for pitch detector initialization
-(void)startPitch{
    
    _sampleRate = 44100;
    _framesSize = 4096;
    
    _audioController = [[AudioController alloc] init:_sampleRate FrameSize:_framesSize];
    _bufferManager = [_audioController getBufferManagerInstance];
    _l_fftData = (Float32*) calloc(_framesSize, sizeof(Float32));
    _l_cepstrumData = (Float32*) calloc(_framesSize, sizeof(Float32));
    _l_fftcepstrumData = (Float32*) calloc(_framesSize, sizeof(Float32));
    
    _sampleRate = [_audioController sessionSampleRate];
    
    _Hz120 = floor(120*(float)_framesSize/(float)_sampleRate);
    _Hz530 = floor(530*(float)_framesSize/(float)_sampleRate);
    
    [_audioController startIOUnit];
    
}


//Method for Song Player initialization
-(void)startApp:(NSString*)pianoName{
    
    checkPitch = 1; //Initial value of pitch checking
    songIsOver = 0; //Exit or replay state
    isPausedScene = 0; //Paused or not state
    
    //scaling properties
    scaleH = 320/self.frame.size.height;
    scaleW = 568/self.frame.size.width;
    
    statusGo = 0; //The state of whether loading time is over or not
    loading  = 2; // seconds to wait before everything is loaded
    
    firstColision = 0; //TO calculate amount of first collision
    
    //Load the noteBar
    NoteBox = [SKSpriteNode spriteNodeWithImageNamed:@"1beat.png"];
    oneBeatLength = NoteBox.frame.size.width;
    
    
    index = 0; //For loading note, to indicate which note is going to be rendered after the other left the right side of the screen
    idx = 1; //for ClashCheck, noteInput is never changed, just the index is increased by one to indicate
    //the first note that is going to hit the bar
    
    buffer  = 3; //The amount of pixel each note is rendered towards the left, to overcome the slight delay of update
    NoteInput = [[NSMutableArray alloc]init]; //The input note from string to the array and going to be rendered
    NoteOutput = [[NSMutableArray alloc]init]; //The output array note that is going to be removed from screen
    
    secPerBeat = 60.0/tempo;
    
    //Calculating speed : if length of note is x, it has to move x distance in secPerbeat if x is 1 beat.
    speed = oneBeatLength/secPerBeat;
    
    octaveValue = 12;
    notesPerScreen = 25;
    noteHeight = self.frame.size.height/ notesPerScreen;
    octaveLength = octaveValue * noteHeight;
    
    //Scorebar is position at the third left of the screen
    scoreBarXpos = self.frame.size.width/3;
    
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
    ScoreBar.position = CGPointMake(scoreBarXpos, CGRectGetMidY(self.frame));
    [self addChild:ScoreBar];
    
    //Draw Piano Roll
    SKSpriteNode *pianoRoll = [SKSpriteNode spriteNodeWithImageNamed:pianoName];
    pianoRoll.zPosition = 1;
    pianoRoll.position = CGPointMake(scoreBarXpos-pianoRoll.self.frame.size.width/2, CGRectGetMidY(self.frame));
    pianoRoll.name = @"PIANO";
    [self addChild:pianoRoll];
    
    //Draw pause Button
    pause = [SKSpriteNode spriteNodeWithImageNamed:@"Pause.png"];
    pause.zPosition = 3;
    pause.anchorPoint = CGPointMake(0, 0);
    pause.position = CGPointMake(568-18,3);
    pause.xScale = 0.5;
    pause.yScale = 0.5;
    [self addChild:pause];
    
    //Draw pauseword
    SKSpriteNode *pauseword = [SKSpriteNode spriteNodeWithImageNamed:@"pauseWord.png"];
    pauseword.zPosition = 6;
    pauseword.anchorPoint = CGPointMake(0, 0);
    pauseword.xScale = 0.4;
    pauseword.yScale = 0.5;
    pauseword.position = CGPointMake(568-20.5, 31);
    [self addChild:pauseword];
    
    //Make pause overlay
    PauseOverlay = [SKSpriteNode spriteNodeWithImageNamed:@"PauseOverlay.png"];
    PauseOverlay.anchorPoint = CGPointMake(0, 0);
    PauseOverlay.position = CGPointMake(0, 0);
    PauseOverlay.zPosition = 5;
    
    //Make gameover overlay
    songOver = [SKSpriteNode spriteNodeWithImageNamed:@"gameover.png"];
    songOver.anchorPoint = CGPointMake(0, 0);
    songOver.position = CGPointMake(0, 0);
    songOver.zPosition = 10;
    
}


//Method to setup musicPlayer
-(void)playMusic:(NSString*)SongName
withShortStartDelay:(NSTimeInterval)shortStartDelay{
    
    NSError *err;
    NSString *path  = [[NSBundle mainBundle] pathForResource:SongName ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:path];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    if (err){
        NSLog (@"Cannot Load audio");
    }
    else{
        NSLog(@"succeed!");
        [_player playAtTime:currTime + shortStartDelay];
    }
}

//Method to initialize Arrow
-(void)MakeArrow{
    
    SKNode *Piano = [self childNodeWithName:@"PIANO"];
    moveBy = -1.0; //Can be editable, -1.0 means move 1 pixel to the left each time
    
    paths = [[NSMutableArray alloc]init];
    
    Arrow = [SKSpriteNode spriteNodeWithImageNamed:@"arrow2.png"];
    
    //offset is the distance from arrow middle to the end of the arrow, value is fixed
    offset = 13;
    
    starting = Piano.frame.origin.x - offset;
    Arrow.position = CGPointMake(starting, 200);
    Arrow.xScale = 0.3;
    Arrow.yScale = 0.3;
    Arrow.zPosition = 2;
    Arrow.name = @"ARROW";
    [self addChild:Arrow];
    
    //Setting up tail path
    pathToDraw = CGPathCreateMutable();
    CGPathMoveToPoint(pathToDraw, NULL, starting, 200);
    lineNode = [SKShapeNode node];
    lineNode.path = pathToDraw;
    lineNode.strokeColor = [SKColor blackColor];
    lineNode.lineWidth = 0.5;
    lineNode.zPosition = 2;
    [self addChild:lineNode];
    
    
}

//Method to determine what happens if touch begins
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    CGPoint location =[ [touches anyObject] locationInNode:self];
    
    CGRect resume = CGRectMake(173, 320-170, 90, 28);
    CGRect exit  = CGRectMake(311, 320-171, 90, 28);
    CGRect pauseButton = CGRectMake(568-15-3, 3, 15, 30);
    
    if (songIsOver == 0){
        if (CGRectContainsPoint(pauseButton, location)){
            //Do this instead of pausing right away is to give time for the pauseOverlay to appear on the screen
            [self addChild:PauseOverlay];
            isPausedScene= 1;
            
            NSLog(@"Pausing song");
        }
        
        else if (self.view.isPaused){
            if (CGRectContainsPoint(resume, location)){
                NSLog(@"Resuming song");
                [PauseOverlay removeFromParent];
                [_player play];
                self.view.paused = NO;
                isPausedScene = 0;
            }
            else if (CGRectContainsPoint(exit, location)){
                NSLog(@"Exiting Song");
                self.view.paused = NO;
                isPausedScene = 0;
                
                SKScene *songChoose = [SongChooseMenu sceneWithSize:self.size];
                songChoose.scaleMode = SKSceneScaleModeAspectFill;
                
                [self.view presentScene:songChoose transition:[SKTransition fadeWithDuration:1.5]];
                
            }
        }}
    
    else if (songIsOver == 1){
        CGRect replay = CGRectMake(173, 320-184, 91, 26);
        CGRect exitSong = CGRectMake(313, 320-184, 91, 26);
        
        if (CGRectContainsPoint(replay, location)){
            SKScene *replaySong = [[MyScene alloc]initWithSize:self.size withSongName:_songName withTempo:tempo withDelay:_delay withInput:StringInput withC3YPos:C3Ypos withPianoName:_pianoName];
            replaySong.scaleMode = SKSceneScaleModeAspectFill;
            [self.view presentScene:replaySong transition:[SKTransition crossFadeWithDuration:1.5]];
        }
        else if (CGRectContainsPoint(exitSong, location)){
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

-(int)getNoteDistance:(NSString*)noteName{
    int answer = 0;
    
    NSString* oct = [noteName substringFromIndex:noteName.length-1];
    NSString* newNoteName = [noteName substringToIndex:noteName.length-1];
    int difference = (oct.integerValue - 3)*octaveValue;
    
    if ([newNoteName compare:@"C"]==0){
        answer = 0 + difference;
        return answer;
    }
    else if([newNoteName compare:@"C#"]==0 || [newNoteName compare:@"Db"] == 0){
        answer = 1 + difference;
        return answer;
    }
    else if([newNoteName compare:@"D"]==0){
        answer = 2 + difference;
        return answer;
    }
    else if([newNoteName compare:@"D#"]==0 || [newNoteName compare:@"Eb"] == 0){
        answer = 3 + difference;
        return answer;
    }
    else if([newNoteName compare:@"E"]==0){
        answer = 4 + difference;
        return answer;
    }
    else if([newNoteName compare:@"F"]==0){
        answer = 5 + difference;
        return answer;
    }
    else if([newNoteName compare:@"F#"]==0 || [newNoteName compare:@"Gb"]==0){
        answer = 6 + difference;
        return answer;
    }
    else if([newNoteName compare:@"G"] ==0){
        answer = 7 + difference;
        return answer;
    }
    else if([newNoteName compare:@"G#"]==0 || [newNoteName compare:@"Ab"]==0){
        answer = 8 + difference;
        return answer;
    }
    else if([newNoteName compare:@"A"]==0){
        answer = 9 + difference;
        return answer;
    }
    else if([newNoteName compare:@"A#"]==0 || [newNoteName compare:@"Bb"]==0){
        answer = 10 + difference;
        return answer;
    }
    else if([newNoteName compare:@"B"] == 0){
        answer = 11 + difference;
        return answer;
    }
    
    return answer;
}



//method called by update to add and render note to the screen whenever the previous note has entirely left the screen
-(void)loadNote{
    
    if (index < NoteInput.count){
        NoteClass *toGo = [NoteInput objectAtIndex:index];
        SKSpriteNode *toGoNode = [toGo getNoteShape];
        
        float duration = (framesize.width + [toGo getLength])/speed;
        
        CGPoint point = CGPointMake(toGoNode.frame.origin.x - buffer, toGoNode.frame.origin.y);
        toGoNode.position = point;
        
        SKAction *goLeft = [SKAction moveToX:(0 - [toGo getLength]) duration:duration];
        [toGoNode runAction:goLeft];
        CurrentNode = toGo;
        [NoteOutput addObject:toGo];
        
        [self addChild:toGoNode];
        index++;
    }
    else{
        //Do nothing, no more note to load
    }
}

//Method called by Update to remove notes from the screen as soon as they have finished travelling the whole width of screen

-(void)unloadNote{
    NoteClass *toRemoveNode = [NoteOutput objectAtIndex:0];
    
    SKSpriteNode *RM = [toRemoveNode getNoteShape];
    [RM removeFromParent];
    [NoteOutput removeObjectAtIndex:0];
    FrontNode = [NoteOutput objectAtIndex:0];
    
    if (NoteOutput.count == 1){
        
        [self addChild:songOver];
        songIsOver = 1;
        
    }
    
}



//Method that is called by Update to check clash between note and scoreBar
-(void)clashCheck{
    NSString *pitchHitNode = [HittingNode getPitch];
    SKSpriteNode *clash = [HittingNode getNoteShape];
    SKNode *bar = [self childNodeWithName:@"BAR"];
    float barMax = CGRectGetMaxX(bar.frame);
    float noteMin = CGRectGetMinX(clash.frame);
    float barMin = CGRectGetMinX(bar.frame);
    
    /*
     if (barMin < noteMin && noteMin < barMax && [pitchHitNode compare:@"rest"] != 0){
     if (firstColision == 0){
     firstColision = 1;
     double time = CACurrentMediaTime();
     double timeDelay = time - currTime;
     printf("\n first collision time %f", timeDelay);
     
     }
     
     
     //  printf("Arrow is at : %f \n",Arrow.self.frame.origin.y);
     
     }
     else if ((noteMin < barMin && idx < NoteInput.count) || ([pitchHitNode compare:@"rest"] == 0 && idx < NoteInput.count)){
     HittingNode = [NoteInput objectAtIndex:idx];
     idx++;
     }
     
     */
    //Special effects of clashing
    
    NSString *pitchHitNodeSpark = [SparkledNode getPitch];
    SKSpriteNode *spark = [SparkledNode getNoteShape];
    float noteMinSpark = CGRectGetMinX(spark.frame);
    
    if(barMin < noteMinSpark && noteMinSpark < barMax && idx< NoteInput.count && [pitchHitNodeSpark compare:@"rest"] != 0){
        
        SKEmitterNode *explosionTwo = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"explode" ofType:@"sks"]];
        [explosionTwo setNumParticlesToEmit:20];
        explosionTwo.position = CGPointMake(scoreBarXpos, [SparkledNode getyLocation] + 5);
        explosionTwo.zPosition = 5;
        explosionTwo.xScale = 0.3;
        explosionTwo.yScale = 0.3;
        [self addChild:explosionTwo];
        
        SparkledNode = [NoteInput objectAtIndex:idx];
        idx++;
        
        
    }
    else if ([pitchHitNodeSpark compare:@"rest"] == 0 && idx < NoteInput.count){
        SparkledNode = [NoteInput objectAtIndex:idx];
        idx++;
    }
    
}



//Method called by Update to move the tail of the arrow
-(void)ArrowMove{
    
    CGPoint newPt = CGPointMake(Arrow.frame.origin.x + 5, Arrow.frame.origin.y + (Arrow.frame.size.height/2));
    [paths addObject:[NSValue valueWithCGPoint:newPt]];
    
    CGMutablePathRef path2 = CGPathCreateMutable();
    NSValue *startingValue = [paths objectAtIndex:0];
    CGPoint st = startingValue.CGPointValue;
    CGPathMoveToPoint(path2, NULL, st.x, st.y);
    
    //Remove points from array as soon as it has exceeded the screen
    if (st.x < 1){
        [paths removeObjectAtIndex:0];
        startingValue = [paths objectAtIndex:0];
        st = startingValue.CGPointValue;
        CGPathMoveToPoint(path2, NULL, st.x, st.y);
    }
    
    //Move everybody by "moveBy" pixel and render
    for (int i = 0; i<[paths count]; i++){
        NSValue *temp = [paths objectAtIndex:i];
        CGPoint tempPt = temp.CGPointValue;
        tempPt.x = tempPt.x + moveBy;
        [paths replaceObjectAtIndex:i withObject:[NSValue valueWithCGPoint:tempPt]];
        
        //add all the lines to the new path
        CGPathAddLineToPoint(path2, NULL, tempPt.x, tempPt.y);
    }
    
    //make a copy of the new path
    pathToDraw = path2;
    //plug in to lineNode
    lineNode.path = pathToDraw;
    
}

//Method called by Update to check pitch of the input Soundwave
-(void)pitchUpdate{
    
    _pitch = [_audioController EstimatePitch];
    int distance = [self getNoteDistance:_pitch];
    float yPositionforArrow  =  C3Ypos + 13* distance + 1;
    
    if (yPositionforArrow <0){
        yPositionforArrow = 0 + 3;
    }
    else if(yPositionforArrow > framesize.height){
        yPositionforArrow = framesize.height - 3;
    }
    
    CGPoint position = CGPointMake(starting, yPositionforArrow + 5);
    SKAction *moveToLocation = [SKAction moveTo:position duration:0.2];
    [Arrow runAction:moveToLocation];
    
    /*
     if (_bufferManager != NULL)
     {
     if(_bufferManager->HasNewFFTData())
     {
     [_audioController GetFFTOutput:_l_fftData];
     _bufferManager->GetCepstrumOutput(_l_fftData, _l_cepstrumData);
     _bufferManager->GetFFTCepstrumOutput(_l_fftData, _l_cepstrumData, _l_fftcepstrumData);
     
     _maxAmp = -INFINITY;
     _bin = _Hz120;
     for (int i=_Hz120; i<=_Hz530; i++)
     {
     _curAmp = _l_fftcepstrumData[i];
     if (_curAmp > _maxAmp)
     {
     _maxAmp = _curAmp;
     _bin = i;
     }
     }
     
     _frequency = _bin*((float)_sampleRate/(float)_framesSize);
     _midiNum = [_audioController freqToMIDI:_frequency];
     _pitch = [_audioController midiToPitch:_midiNum];
     
     int distance = [self getNoteDistance:_pitch];
     float yPositionforArrow  =  C3Ypos + 13* distance + 1;
     
     if (yPositionforArrow <0){
     yPositionforArrow = 0 + 3;
     }
     else if(yPositionforArrow > framesize.height){
     yPositionforArrow = framesize.height - 3;
     }
     
     CGPoint position = CGPointMake(starting, yPositionforArrow + 5);
     SKAction *moveToLocation = [SKAction moveTo:position duration:0.2];
     [Arrow runAction:moveToLocation];
     NSLog(@"Current: %.12f %d %.12f %@", _frequency, _bin, _midiNum, _pitch);
     
     _bufferManager->CycleFFTBuffers();
     
     memset(_l_fftData, 0, _framesSize*sizeof(Float32));
     memset(_l_cepstrumData, 0, _framesSize*sizeof(Float32));
     memset(_l_fftcepstrumData, 0, _framesSize*sizeof(Float32));
     
     }
     }
     */
}


-(void)update:(CFTimeInterval)currentTime {
    
    //Check if self is paused
    if (self.view.isPaused == YES){
        //Do not update anything
    }
    else{
        
        //Check whether pausedScene state is 1 = paused button pressed
        if (isPausedScene == 1){
            [_player pause];
            self.view.paused = YES;
            
        }
        
        //Checking whether loading time has been exceeded
        if (currentTime - currTime > loading){
            if (statusGo == 0){
                statusGo = 1;
                [self loadNote];
                [self ArrowMove];
            }
            [self ArrowMove];
            
            //Do Note Loading
            SKSpriteNode *currNode = [CurrentNode getNoteShape];
            float location = currNode.frame.origin.x;
            float nextNode = framesize.width - [CurrentNode getLength];
            if (location < nextNode && index < NoteInput.count){
                [self loadNote];
            }
            
            //Do Note unloading
            SKSpriteNode *frntNode = [FrontNode getNoteShape];
            float myLocation = frntNode.frame.origin.x;
            if (myLocation <= 0 - (frntNode.self.frame.size.width) && NoteOutput.count > 1){
                [self unloadNote];
            }
            
            //Do ClashCheck
            [self clashCheck];
            
            //Do Pitch Detection
            if (checkPitch%7 == 0){
                [self pitchUpdate];
                
                checkPitch = 1;
            }
            else{
                checkPitch ++;
            }
            
        }
    }
    
}

@end
