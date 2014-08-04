//
//  SongChooseMenu.mm
//  TheSingingCoach
//
//  Created by Natalie and Edward on 11/6/14.
//  Copyright (c) 2014 Natalie and Edward. All rights reserved.
//
#import "SongChooseMenu.h"

@implementation SongChooseMenu

-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        _scaleH = size.height / 320;
        _scaleW = size.width / 568;
        
        _userDefs = [NSUserDefaults standardUserDefaults];
        
        _cusSongState = 0;
        _listenButtonChandelierState = 0;
        _fileNotFound = 0;
        _SaySomethingListenState = 0;
        _WingsListenState = 0;
        _DemonsListenState = 0;
        
        SKSpriteNode *BG  = [SKSpriteNode spriteNodeWithImageNamed:@"SelectSong.png"];
        BG.anchorPoint = CGPointMake(0,0);
        BG.position = CGPointMake(0, 0);
        BG.xScale = _scaleW;
        BG.yScale = _scaleH;
        [self addChild:BG];
        
        SKSpriteNode *Chandelier = [SKSpriteNode spriteNodeWithImageNamed:@"Chandelier.png"];
        Chandelier.anchorPoint = CGPointMake(0,0);
        Chandelier.position = CGPointMake(94*_scaleW,(320-109)*_scaleH);
        Chandelier.xScale = _scaleW;
        Chandelier.yScale = _scaleH;
        [self addChild:Chandelier];
        
        _ChandelierListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"ListenOff.png"];
        _ChandelierListenNode.anchorPoint = CGPointMake(0, 0);
        _ChandelierListenNode.position = CGPointMake(320*_scaleW , (320 -111)*_scaleH);
        _ChandelierListenNode.name = @"ChandelierListenNode";
        _ChandelierListenNode.xScale = _scaleW;
        _ChandelierListenNode.yScale = _scaleH;
        [self addChild:_ChandelierListenNode];
        
        SKSpriteNode *saySomething = [SKSpriteNode spriteNodeWithImageNamed:@"SaySomething.png"];
        saySomething.anchorPoint = CGPointMake(0, 0);
        saySomething.position = CGPointMake(94, 320-172);
        [self addChild:saySomething];
   
        _SaySomethingListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"ListenOff.png"];
        _SaySomethingListenNode.anchorPoint = CGPointMake(0, 0);
        _SaySomethingListenNode.position = CGPointMake(320, 320-173);
        [self addChild:_SaySomethingListenNode];
        
        SKSpriteNode *wings = [SKSpriteNode spriteNodeWithImageNamed:@"wings.png"];
        wings.anchorPoint = CGPointMake(0, 0);
        wings.position  = CGPointMake( 92, 320-240);
        [self addChild:wings];
        
        _DemonsListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"ListenOff.png"];
        _DemonsListenNode.anchorPoint = CGPointMake(0, 0);
        _DemonsListenNode.position = CGPointMake(320, 320-307);
        [self addChild:_DemonsListenNode];
        
        _WingsListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"ListenOff.png"];
        _WingsListenNode.anchorPoint = CGPointMake(0, 0);
        _WingsListenNode.position = CGPointMake(320, 320-241);
        [self addChild:_WingsListenNode];
        
        SKSpriteNode* demons = [SKSpriteNode spriteNodeWithImageNamed:@"Demons.png"];
        demons.anchorPoint = CGPointMake(0, 0);
        demons.position = CGPointMake(94, 320-301);
        [self addChild:demons];
        
        SKSpriteNode *CustomSong = [SKSpriteNode spriteNodeWithImageNamed:@"CustomSong.png"];
        CustomSong.anchorPoint = CGPointMake(0, 0);
        CustomSong.position = CGPointMake(94*_scaleW, (320-43)*_scaleH);
        CustomSong.xScale = _scaleW;
        CustomSong.yScale=_scaleH;
        [self addChild:CustomSong];
        
        _customSongOvr = [SKSpriteNode spriteNodeWithImageNamed:@"customSongOverlay.png"];
        _customSongOvr.anchorPoint = CGPointMake(0, 0);
        _customSongOvr.position = CGPointMake(0, 0);
        _customSongOvr.xScale = _scaleW;
        _customSongOvr.yScale = _scaleH;
        [self setupTextField];
        
        _FileNotFound = [SKSpriteNode spriteNodeWithImageNamed:@"filenotfound.png"];
        _FileNotFound.anchorPoint = CGPointMake(0, 0);
        _FileNotFound.position = CGPointMake(0, 0);
        _FileNotFound.xScale = _scaleW;
        _FileNotFound.yScale = _scaleH;
    }
    return self;
}

-(void) setupTextField
{
    _textField = [[UITextField alloc]initWithFrame:[self fieldRect]];
    _textField.backgroundColor = [UIColor clearColor];
    _textField.textColor = [UIColor blackColor];
    _textField.font = [UIFont fontWithName:@"IowanOldStyle-Roman" size:20 ];
    _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textField.autocorrectionType = UITextAutocorrectionTypeNo;
    _textField.keyboardType = UIKeyboardTypeDefault;
    _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _textField.placeholder = @"Enter file name";
    _textField.tintColor = [UIColor blackColor];
    _textField.delegate = self;
    
    
}

-(BOOL) textFieldShouldReturn:(UITextField *)theTextField
{
    [self processReturn];
    return YES;
}

-(void) processReturn
{
    [_textField resignFirstResponder];

    if ([_textField.text compare:@""] != 0){
        NSError *error;
        NSArray* dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
        NSString* docsDir = [dirPaths[0] stringByAppendingString:@"/"];
        NSString* filePath = [[docsDir stringByAppendingString:_textField.text] stringByAppendingString:@".txt"];
        NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        
        if (error)
        {
            NSLog(@"Error reading file: %@", error.localizedDescription);
            NSLog(@"filePath: %@", filePath);
            
            _fileNotFound = 1;
            [_textField removeFromSuperview];
            [self addChild:_FileNotFound];
        }
        else
        {
            //Create the custom song scene here
            [_textField removeFromSuperview];
            
            //NSLog(fileContents);
            NSMutableArray *listArray = [NSMutableArray arrayWithArray:[fileContents componentsSeparatedByString:@"\n"]];
            NSString *lyricsName = [listArray objectAtIndex:0];
            [listArray removeObjectAtIndex:0];
            NSString* lyricsDuration = [listArray objectAtIndex:0];
            [listArray removeObjectAtIndex:0];
            float lyricsDurationfloat = [lyricsDuration floatValue];
            NSString *pianoName = [listArray objectAtIndex:0];
            [listArray removeObjectAtIndex:0];
            float C3YPos = [self getC3YPos:pianoName];
            NSString *songName = [listArray objectAtIndex:0];
            [listArray removeObjectAtIndex:0];

            
            NSString *tempoString = [listArray objectAtIndex:0];
          
            
            float tempo = [tempoString floatValue];
            [listArray removeObjectAtIndex:0];
            NSString *delayString = [listArray objectAtIndex:0];

            
            float delay = [delayString floatValue];
            [listArray removeObjectAtIndex:0];
            SKScene *customSongScene = [[HeadPhones alloc]initWithSize:self.size withSongName:songName withTempo:tempo withDelay:delay withInput:listArray withC3YPos:C3YPos withPianoName:pianoName withLyrics:lyricsName withLyricsDuration:lyricsDurationfloat];
            customSongScene.scaleMode = SKSceneScaleModeAspectFill;
            
            [self.view presentScene:customSongScene transition:[SKTransition fadeWithDuration:1.5f]];
        }
    }
}


-(CGRect)fieldRect
{
    return CGRectMake(168*_scaleW, 118*_scaleH, 235*_scaleW, 26*_scaleH);
}

-(void)update:(NSTimeInterval)currentTime
{
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint location =[ [touches anyObject] locationInNode:self];
    NSError* err;
    NSString* path  = [[NSBundle mainBundle] pathForResource:@"button" ofType:@"mp3"];
    NSURL* url = [NSURL fileURLWithPath:path];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    
    if (_fileNotFound == 0)
    {
        if (_cusSongState == 0)
        {
            CGRect Chandelier = CGRectMake(78*_scaleW, (320-126)*_scaleH, 200*_scaleW, 64*_scaleH);
            CGRect ChandelierListen = CGRectMake(320*_scaleW, (320-111)*_scaleH,60*_scaleW,60*_scaleH);
            
            CGRect SaySomething = CGRectMake(78, 320-190, 200, 64);
            CGRect SaySomethingListen = CGRectMake(320, 320-173, 60, 60);
            
            CGRect Wings = CGRectMake(78, 320-255, 200, 64);
            CGRect WingsListen = CGRectMake(320, 320-241, 60, 60);
            
            NSString* ChandelierPath = [[NSBundle mainBundle] pathForResource:@"chandelier" ofType:@"mp3"];
            NSURL* ChandelierURL = [NSURL fileURLWithPath:ChandelierPath];
            
            NSString* saysomethingPath = [[NSBundle mainBundle] pathForResource:@"saysomething" ofType:@"mp3"];
            NSURL* SaySomethingURL = [NSURL fileURLWithPath:saysomethingPath];
            
            NSString* WingsPath = [[NSBundle mainBundle] pathForResource:@"wings" ofType:@"mp3"];
            NSURL* WingsURL = [NSURL fileURLWithPath:WingsPath];
            
            CGRect Demons = CGRectMake(78, 0, 200, 64);
            CGRect DemonsListen = CGRectMake(320, 320-307, 60, 60);
            
            NSString* DemonsPath = [[NSBundle mainBundle]pathForResource:@"demons" ofType:@"mp3"];
            NSURL* DemonsURL = [NSURL fileURLWithPath:DemonsPath];
    
            CGRect CustomSong = CGRectMake(78*_scaleW,( 320-62)*_scaleH, 323*_scaleW, 64*_scaleH);
            CGRect exitButton = CGRectMake(0*_scaleW, (320-86)*_scaleH, 74*_scaleW  , 86*_scaleH);

            if (CGRectContainsPoint(Demons, location)){
                [_userDefs setInteger:4 forKey:@"songType"];
                [_listenDemons stop];
                [_player play];
                
                NSLog(@"Song Beginning");
                
                NSString *fileName = @"imagineDragons";
                NSString *filepath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"txt"];
                NSError *error;
                NSString *fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
                
                if (error)
                {
                    NSLog(@"Error reading file: %@", error.localizedDescription);
                    _fileNotFound = 1;
                    [_textField removeFromSuperview];
                    [self addChild:_FileNotFound];
                }
                else
                {
                    NSMutableArray* listArray = [NSMutableArray arrayWithArray:[fileContents componentsSeparatedByString:@"\n"]];
                    NSString* lyricsName = [listArray objectAtIndex:0];
                    [listArray removeObjectAtIndex:0];
                    NSString* lyricsDuration = [listArray objectAtIndex:0];
                    [listArray removeObjectAtIndex:0];
                    float lyricsDurationFloat = [lyricsDuration floatValue];
                    NSString* pianoName = [listArray objectAtIndex:0];
                    [listArray removeObjectAtIndex:0];
                    float C3YPos = [self getC3YPos:pianoName];
                    NSString* songName = [listArray objectAtIndex:0];
                    [listArray removeObjectAtIndex:0];
                    NSString* tempoString = [listArray objectAtIndex:0];
                    float tempo = [tempoString floatValue];
                    [listArray removeObjectAtIndex:0];
                    NSString* delayString = [listArray objectAtIndex:0];
                    float delay = [delayString floatValue];
                    [listArray removeObjectAtIndex:0];
                    SKScene* SongScene = [[HeadPhones alloc]initWithSize:self.size
                                                            withSongName:songName
                                                               withTempo:tempo
                                                               withDelay:delay
                                                               withInput:listArray
                                                              withC3YPos:C3YPos
                                                           withPianoName:pianoName
                                                              withLyrics:lyricsName
                                                      withLyricsDuration:lyricsDurationFloat];
                    SongScene.scaleMode = SKSceneScaleModeAspectFill;
                    [self.view presentScene:SongScene transition:[SKTransition fadeWithDuration:1.5f]];
                
            }

            }
            if (CGRectContainsPoint(Chandelier, location))
            {
                [_userDefs setInteger:1 forKey:@"songType"];
                if (err)
                    NSLog (@"Cannot Load audio");
                else
                {
                    [_player play];
                    [_listen stop];
                    //Add button pressed effect
                    NSLog(@"Song Beginning");
            
                    NSString *fileName = @"chandelierSia";
                    NSString *filepath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"txt"];
                    NSError *error;
                    NSString *fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
            
                    if (error)
                    {
                        NSLog(@"Error reading file: %@", error.localizedDescription);
                        _fileNotFound = 1;
                        [_textField removeFromSuperview];
                        [self addChild:_FileNotFound];
                    }
                    else
                    {
                        NSMutableArray* listArray = [NSMutableArray arrayWithArray:[fileContents componentsSeparatedByString:@"\n"]];
                        NSString* lyricsName = [listArray objectAtIndex:0];
                        [listArray removeObjectAtIndex:0];
                        NSString* lyricsDuration = [listArray objectAtIndex:0];
                        [listArray removeObjectAtIndex:0];
                        float lyricsDurationFloat = [lyricsDuration floatValue];
                        NSString* pianoName = [listArray objectAtIndex:0];
                        [listArray removeObjectAtIndex:0];
                        float C3YPos = [self getC3YPos:pianoName];
                        NSString* songName = [listArray objectAtIndex:0];
                        [listArray removeObjectAtIndex:0];
                        NSString* tempoString = [listArray objectAtIndex:0];
                        float tempo = [tempoString floatValue];
                        [listArray removeObjectAtIndex:0];
                        NSString* delayString = [listArray objectAtIndex:0];
                        float delay = [delayString floatValue];
                        [listArray removeObjectAtIndex:0];
                        SKScene* SongScene = [[HeadPhones alloc]initWithSize:self.size
                                                                   withSongName:songName
                                                                      withTempo:tempo
                                                                      withDelay:delay
                                                                      withInput:listArray
                                                                     withC3YPos:C3YPos
                                                                  withPianoName:pianoName
                                              withLyrics:lyricsName
                                              withLyricsDuration:lyricsDurationFloat];
                        SongScene.scaleMode = SKSceneScaleModeAspectFill;
                        [self.view presentScene:SongScene transition:[SKTransition fadeWithDuration:1.5f]];
                    }
                }
            }
            else if (CGRectContainsPoint(Wings, location))
            {
                [_userDefs setInteger:3 forKey:@"songType"];
                [_player play];
                [_listenWings stop];
                NSString *fileName = @"birdy";
                NSString *filepath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"txt"];
                NSError *error;
                NSString *fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
                
                if (error)
                {
                    NSLog(@"Error reading file: %@", error.localizedDescription);
                }
                else
                {
                    NSMutableArray* listArray = [NSMutableArray arrayWithArray:[fileContents componentsSeparatedByString:@"\n"]];
                    NSString* lyricsName = [listArray objectAtIndex:0];
                    [listArray removeObjectAtIndex:0];
                    NSString* lyricsDuration = [listArray objectAtIndex:0];
                    [listArray removeObjectAtIndex:0];
                    float lyricsDurationFloat = [lyricsDuration floatValue];
                    NSString* pianoName = [listArray objectAtIndex:0];
                    [listArray removeObjectAtIndex:0];

                    float C3YPos = [self getC3YPos:pianoName];

                    NSString* songName = [listArray objectAtIndex:0];
                    [listArray removeObjectAtIndex:0];
                    NSString* tempoString = [listArray objectAtIndex:0];
                    float tempo = [tempoString floatValue];
                    [listArray removeObjectAtIndex:0];
                    NSString* delayString = [listArray objectAtIndex:0];
                    float delay = [delayString floatValue];
                    [listArray removeObjectAtIndex:0];
                    SKScene* SongScene = [[HeadPhones alloc]initWithSize:self.size
                                                            withSongName:songName
                                                               withTempo:tempo
                                                               withDelay:delay
                                                               withInput:listArray
                                                              withC3YPos:C3YPos
                                                           withPianoName:pianoName
                                                              withLyrics:lyricsName
                                                      withLyricsDuration:lyricsDurationFloat];
                    SongScene.scaleMode = SKSceneScaleModeAspectFill;
                    [self.view presentScene:SongScene transition:[SKTransition fadeWithDuration:1.5f]];
                }
                

            }
            else if (CGRectContainsPoint(SaySomething, location))
            {
                [_userDefs setInteger:2 forKey:@"songType"];
                [_player play];
                [_listenSaySomething stop];
                NSString *fileName = @"saysomething";
                NSString *filepath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"txt"];
                NSError *error;
                NSString *fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
                
                if (error)
                {
                    NSLog(@"Error reading file: %@", error.localizedDescription);
                }
                else
                {
                    NSMutableArray* listArray = [NSMutableArray arrayWithArray:[fileContents componentsSeparatedByString:@"\n"]];
                    NSString* lyricsName = [listArray objectAtIndex:0];
                    [listArray removeObjectAtIndex:0];
                    NSString* lyricsDuration = [listArray objectAtIndex:0];
                    [listArray removeObjectAtIndex:0];
                    float lyricsDurationFloat = [lyricsDuration floatValue];
                    NSString* pianoName = [listArray objectAtIndex:0];
                    [listArray removeObjectAtIndex:0];

                    float C3YPos = [self getC3YPos:pianoName];

                    NSString* songName = [listArray objectAtIndex:0];
                    [listArray removeObjectAtIndex:0];
                    NSString* tempoString = [listArray objectAtIndex:0];
                    float tempo = [tempoString floatValue];
                    [listArray removeObjectAtIndex:0];
                    NSString* delayString = [listArray objectAtIndex:0];
                    float delay = [delayString floatValue];
                    [listArray removeObjectAtIndex:0];
                    SKScene* SongScene = [[HeadPhones alloc]initWithSize:self.size
                                                            withSongName:songName
                                                               withTempo:tempo
                                                               withDelay:delay
                                                               withInput:listArray
                                                              withC3YPos:C3YPos
                                                           withPianoName:pianoName
                                                              withLyrics:lyricsName
                                                      withLyricsDuration:lyricsDurationFloat];
                    SongScene.scaleMode = SKSceneScaleModeAspectFill;
                    [self.view presentScene:SongScene transition:[SKTransition fadeWithDuration:1.5f]];
                }

                
            }
            
            else if (CGRectContainsPoint(SaySomethingListen, location) && _SaySomethingListenState == 0){
                _listenSaySomething = [[AVAudioPlayer alloc]initWithContentsOfURL:SaySomethingURL error:&err];
                if (err)
                    NSLog(@"Cannot load audio");
                else
                {
                    _SaySomethingListenState = 1;
                    [_SaySomethingListenNode removeFromParent];
                    
                    _SaySomethingListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"Listen.png"];
                    _SaySomethingListenNode.anchorPoint = CGPointMake(0, 0);
                    _SaySomethingListenNode.position = CGPointMake(320, 320-173);
                    [self addChild:_SaySomethingListenNode];
                    
                    [_listenSaySomething play];
                }
            }
            
            else if (CGRectContainsPoint(DemonsListen, location) && _DemonsListenState == 0){
                _DemonsListenState = 1;
                _listenDemons = [[AVAudioPlayer alloc]initWithContentsOfURL:DemonsURL error:&err];
                
                [_DemonsListenNode removeFromParent];
                _DemonsListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"Listen.png"];
                _DemonsListenNode.anchorPoint = CGPointMake(0, 0);
                _DemonsListenNode.position = CGPointMake(320, 320-307);
                [self addChild:_DemonsListenNode];
                
                [_listenDemons play];
                
                
            }
            else if (CGRectContainsPoint(DemonsListen, location) && _DemonsListenState == 1){
                _DemonsListenState = 0;
                [_listenDemons stop];
                [_DemonsListenNode removeFromParent];
                _DemonsListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"ListenOff.png"];
                _DemonsListenNode.anchorPoint = CGPointMake(0, 0);
                _DemonsListenNode.position = CGPointMake(320, 320-307);
                [self addChild:_DemonsListenNode];
                
            }
            else if (CGRectContainsPoint(WingsListen, location) && _WingsListenState == 0){
                _listenWings = [[AVAudioPlayer alloc]initWithContentsOfURL:WingsURL error:&err];
                if (err)
                    NSLog(@"Cannot load audio");
                else
                {
                    _WingsListenState= 1;
                    [_WingsListenNode removeFromParent];
                    
                    _WingsListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"Listen.png"];
                    _WingsListenNode.anchorPoint = CGPointMake(0, 0);
                    _WingsListenNode.position = CGPointMake(320, 320-241);

                    [self addChild:_WingsListenNode];
                    
                    [_listenWings play];
                }

            }
            
            else if (CGRectContainsPoint(WingsListen, location) && _WingsListenState == 1){
                _WingsListenState = 0;
                [_WingsListenNode removeFromParent];
                
                _WingsListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"ListenOff.png"];
                _WingsListenNode.anchorPoint = CGPointMake(0, 0);
                _WingsListenNode.position = CGPointMake(320, 320-241);
                [self addChild:_WingsListenNode];
                
                [_listenWings stop];
            }
            
            else if (CGRectContainsPoint(ChandelierListen, location) && _listenButtonChandelierState == 0)
            {
                _listen = [[AVAudioPlayer alloc]initWithContentsOfURL:ChandelierURL error:&err];
                if (err)
                    NSLog(@"Cannot load audio");
                else
                {
                    _listenButtonChandelierState = 1;
                    SKNode *CLN = [self childNodeWithName:@"ChandelierListenNode"];
                    [CLN removeFromParent];
            
                    _ChandelierListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"Listen.png"];
                    _ChandelierListenNode.anchorPoint = CGPointMake(0, 0);
                    _ChandelierListenNode.position = CGPointMake(320*_scaleW, (320 -111)*_scaleH);
                    _ChandelierListenNode.name = @"ChandelierListenNode";
                    _ChandelierListenNode.xScale = _scaleW;
                    _ChandelierListenNode.yScale = _scaleH;
                    [self addChild:_ChandelierListenNode];
            
                    [_listen play];
                }
            }
    
            else if (CGRectContainsPoint(SaySomethingListen, location) && _SaySomethingListenState == 1){
                _SaySomethingListenState = 0;
                [_SaySomethingListenNode removeFromParent];
                
                _SaySomethingListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"ListenOff.png"];
                _SaySomethingListenNode.anchorPoint = CGPointMake(0, 0);
                _SaySomethingListenNode.position = CGPointMake(320, 320-173);
                [self addChild:_SaySomethingListenNode];
                
                [_listenSaySomething stop];
            }
            
            else if (CGRectContainsPoint(ChandelierListen, location) && _listenButtonChandelierState == 1)
            {
                _listenButtonChandelierState = 0;
                SKNode *CLN = [self childNodeWithName:@"ChandelierListenNode"];
                [CLN removeFromParent];
        
                _ChandelierListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"ListenOff.png"];
                _ChandelierListenNode.anchorPoint = CGPointMake(0, 0);
                _ChandelierListenNode.position = CGPointMake(320*_scaleW, (320 - 111)*_scaleH);
                _ChandelierListenNode.name = @"ChandelierListenNode";
                _ChandelierListenNode.xScale = _scaleW;
                _ChandelierListenNode.yScale = _scaleH;
                [self addChild:_ChandelierListenNode];
                
                [_listen stop];
            }
    
            else if(CGRectContainsPoint(exitButton, location))
            {
                if(err)
                    NSLog(@"Cannot load audio.");
                else
                {
                    [_player play];
                    NSLog(@"Back clicked!");
                    SKScene *mainMenu = [MainMenu sceneWithSize:self.size];
                    mainMenu.scaleMode = SKSceneScaleModeAspectFill;
            
                    [self.view presentScene:mainMenu transition:[SKTransition fadeWithDuration:1.5f]];
                }
            }
    
            else if (CGRectContainsPoint(CustomSong, location))
            {
                [_userDefs setInteger:0 forKey:@"songType"];
                _cusSongState = 1;
                [_player play];
                [self addChild:_customSongOvr];
                [self.view addSubview:_textField];
            }
        }
        
        else
        {
            CGRect exitCusSong = CGRectMake(337, 320-198, 83, 23);
            
            if (CGRectContainsPoint(exitCusSong, location))
            {
                _cusSongState = 0;
                [_player play];
                [_customSongOvr removeFromParent];
                [_textField removeFromSuperview];
            }
        }
    }
    
    else if(_fileNotFound == 1)
    {
        CGRect retry = CGRectMake(242, 320-198, 84, 22);

        if (CGRectContainsPoint(retry, location))
        {
            NSLog(@"FOF");
            _fileNotFound = 0;
            [_player play];
            _textField.text = @"";
            [self.view addSubview:_textField];
            [_FileNotFound removeFromParent];
        }
    }
}

-(float) getC3YPos:(NSString*)pianoName
{
    if ([pianoName compare:@"pianoA2A4.png"]==0){
        return 35.0;
    }
    else if ([pianoName compare:@"pianoD3D5.png"]==0){
        return -29.0;
    }
    else if([pianoName compare:@"pianoB2B4.png"]==0){
        return 9.0;
    }
    else if ([pianoName compare:@"pianoG2G4.png"]==0){
        return 62.0;
    }
    else if ([pianoName compare:@"pianoG3G5.png"]==0){
        return -94.0;
    }
    return 0;
}
@end
