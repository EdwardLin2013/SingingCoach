//
//  SongChooseMenu.m
//  MelodyTest
//
//  Created by CrimsonLycans on 12/7/14.
//  Copyright (c) 2014 CrimsonLycans. All rights reserved.
//

#import "SongChooseMenu.h"

@implementation SongChooseMenu

-(id)initWithSize:(CGSize)size {
    
    if (self = [super initWithSize:size]) {
        _scaleH = size.height / 320;
        _scaleW = size.width / 568;
        
        _cusSongState = 0;
        _listenButtonChandelierState = 0;
        fileNotFound = 0;
        SKSpriteNode *BG  = [SKSpriteNode spriteNodeWithImageNamed:@"SelectSong.png"];
        BG.anchorPoint = CGPointMake(0,0);
        BG.position = CGPointMake(0, 0);
        BG.xScale = _scaleW;
        BG.yScale = _scaleH;
        [self addChild:BG];
        
        SKSpriteNode *Chandelier = [SKSpriteNode spriteNodeWithImageNamed:@"Chandelier.png"];
        Chandelier.anchorPoint = CGPointMake(0,0);
        Chandelier.position = CGPointMake(94*_scaleW, (320-43)*_scaleH);
        Chandelier.xScale = _scaleW;
        Chandelier.yScale = _scaleH;
        [self addChild:Chandelier];
        
        _ChandelierListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"ListenOff.png"];
        _ChandelierListenNode.anchorPoint = CGPointMake(0, 0);
        _ChandelierListenNode.position = CGPointMake(400*_scaleW , (320 -43)*_scaleH);
        _ChandelierListenNode.name = @"ChandelierListenNode";
        _ChandelierListenNode.xScale = _scaleW;
        _ChandelierListenNode.yScale = _scaleH;
        [self addChild:_ChandelierListenNode];
        
        SKSpriteNode *CustomSong = [SKSpriteNode spriteNodeWithImageNamed:@"CustomSong.png"];
        CustomSong.anchorPoint = CGPointMake(0, 0);
        CustomSong.position = CGPointMake(94*_scaleW,(320-109)*_scaleH);
        CustomSong.xScale = _scaleW;
        CustomSong.yScale=_scaleH;
        [self addChild:CustomSong];
        
        _customSongOvr = [SKSpriteNode spriteNodeWithImageNamed:@"customSongOverlay.png"];
        _customSongOvr.anchorPoint = CGPointMake(0, 0);
        _customSongOvr.position = CGPointMake(0, 0);
        _customSongOvr.xScale = _scaleW;
        _customSongOvr.yScale = _scaleH;
        [self setupTextField];
        
        FileNotFound = [SKSpriteNode spriteNodeWithImageNamed:@"filenotfound.png"];
        FileNotFound.anchorPoint = CGPointMake(0, 0);
        FileNotFound.position = CGPointMake(0, 0);
        FileNotFound.xScale = _scaleW;
        FileNotFound.yScale = _scaleH;
        
        
    }
    return self;
}

-(void) setupTextField{
    
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

-(BOOL) textFieldShouldReturn:(UITextField *)theTextField{
    [self processReturn];
    return YES;
}

-(void) processReturn{
    [_textField resignFirstResponder];
    //Check the file error
    //File error page
    
    NSString *fileName = _textField.text;
    NSString *filepath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"txt"];
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    
    if (error){
        NSLog(@"Error reading file: %@", error.localizedDescription);
        fileNotFound = 1;
        [_textField removeFromSuperview];
        [self addChild:FileNotFound];
    }
    else{
        //Create the custom song scene here
        [_textField removeFromSuperview];
       // NSLog(fileContents);
        NSMutableArray *listArray = [NSMutableArray arrayWithArray:[fileContents componentsSeparatedByString:@"\n"]];
        NSString *pianoName = [listArray objectAtIndex:0];
        [listArray removeObjectAtIndex:0];
        NSString *C3position = [listArray objectAtIndex:0];
        float C3YPos = [C3position floatValue];
        [listArray removeObjectAtIndex:0];
        NSString *songName = [listArray objectAtIndex:0];
        [listArray removeObjectAtIndex:0];
     //   NSLog(songName);
        NSString *tempoString = [listArray objectAtIndex:0];
      //  NSLog(tempoString);
        float tempo = [tempoString floatValue];
        [listArray removeObjectAtIndex:0];
        NSString *delayString = [listArray objectAtIndex:0];
      //  NSLog(delayString);
        float delay = [delayString floatValue];
        [listArray removeObjectAtIndex:0];
        SKScene *customSongScene = [[MyScene alloc]initWithSize:self.size withSongName:songName withTempo:tempo withDelay:delay withInput:listArray withC3YPos:C3YPos withPianoName:pianoName];
        customSongScene.scaleMode = SKSceneScaleModeAspectFill;
        
        [self.view presentScene:customSongScene transition:[SKTransition fadeWithDuration:1.5f]];
    }

    
}


-(CGRect)fieldRect{
    return CGRectMake(168*_scaleW, 118*_scaleH, 235*_scaleW, 26*_scaleH);
}

-(void)update:(NSTimeInterval)currentTime{
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    CGPoint location =[ [touches anyObject] locationInNode:self];
    NSError *err;
    NSString *path  = [[NSBundle mainBundle] pathForResource:@"button" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:path];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    
    if (fileNotFound == 0){

    if (_cusSongState == 0){
    CGRect Chandelier = CGRectMake(78*_scaleW,( 320-62)*_scaleH, 323*_scaleW, 64*_scaleH);
    CGRect ChandelierListen = CGRectMake(400*_scaleW, (320-60)*_scaleH,60*_scaleW,60*_scaleH);
    NSString *ChandelierPath  = [[NSBundle mainBundle] pathForResource:@"chandelier" ofType:@"mp3"];
    NSURL *ChandelierURL = [NSURL fileURLWithPath:ChandelierPath];
    
    CGRect CustomSong = CGRectMake(78*_scaleW, (320-126)*_scaleH, 323*_scaleW, 64*_scaleH);
    CGRect exitButton = CGRectMake(0*_scaleW, (320-86)*_scaleH, 74*_scaleW  , 86*_scaleH);

    
    if (CGRectContainsPoint(Chandelier, location)){
        

        if (err){
            NSLog (@"Cannot Load audio");
        }
        else{
            [_player play];
            [_listen stop];
            //Add button pressed effect
            NSLog(@"Song Beginning");
            
            NSString *fileName = @"chandelierSia";
            NSString *filepath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"txt"];
            NSError *error;
            NSString *fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
            
            if (error){
                NSLog(@"Error reading file: %@", error.localizedDescription);
                fileNotFound = 1;
                [_textField removeFromSuperview];
                [self addChild:FileNotFound];
            }
            
            else{
                //Create the custom song scene here
                NSMutableArray *listArray = [NSMutableArray arrayWithArray:[fileContents componentsSeparatedByString:@"\n"]];
                NSString *pianoName = [listArray objectAtIndex:0];
                [listArray removeObjectAtIndex:0];
                NSString *C3position = [listArray objectAtIndex:0];
                float C3YPos = [C3position floatValue];
                [listArray removeObjectAtIndex:0];
                NSString *songName = [listArray objectAtIndex:0];
                [listArray removeObjectAtIndex:0];
                NSString *tempoString = [listArray objectAtIndex:0];
                float tempo = [tempoString floatValue];
                [listArray removeObjectAtIndex:0];
                NSString *delayString = [listArray objectAtIndex:0];
                float delay = [delayString floatValue];
                [listArray removeObjectAtIndex:0];
                SKScene *customSongScene = [[MyScene alloc]initWithSize:self.size withSongName:songName withTempo:tempo withDelay:delay withInput:listArray withC3YPos:C3YPos withPianoName:pianoName];
                customSongScene.scaleMode = SKSceneScaleModeAspectFill;
                [self.view presentScene:customSongScene transition:[SKTransition fadeWithDuration:1.5f]];
            }
    
            
        }
    }
    else if (CGRectContainsPoint(ChandelierListen, location) && _listenButtonChandelierState == 0){
        _listen = [[AVAudioPlayer alloc]initWithContentsOfURL:ChandelierURL error:&err];
        if (err){
            NSLog(@"Cannot load audio");
            
        }
        else{
            _listenButtonChandelierState = 1;
            SKNode *CLN = [self childNodeWithName:@"ChandelierListenNode"];
            [CLN removeFromParent];
            
            _ChandelierListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"Listen.png"];
            _ChandelierListenNode.anchorPoint = CGPointMake(0, 0);
            _ChandelierListenNode.position = CGPointMake(400*_scaleW, (320 -43)*_scaleH);
            _ChandelierListenNode.name = @"ChandelierListenNode";
            _ChandelierListenNode.xScale = _scaleW;
            _ChandelierListenNode.yScale = _scaleH;
            [self addChild:_ChandelierListenNode];
            
            [_listen play];
        }
    }
    
    else if (CGRectContainsPoint(ChandelierListen, location) && _listenButtonChandelierState == 1){
        _listenButtonChandelierState = 0;
        SKNode *CLN = [self childNodeWithName:@"ChandelierListenNode"];
        [CLN removeFromParent];
        
        _ChandelierListenNode = [SKSpriteNode spriteNodeWithImageNamed:@"ListenOff.png"];
        _ChandelierListenNode.anchorPoint = CGPointMake(0, 0);
        _ChandelierListenNode.position = CGPointMake(400*_scaleW, (320 -43)*_scaleH);
        _ChandelierListenNode.name = @"ChandelierListenNode";
        _ChandelierListenNode.xScale = _scaleW;
        _ChandelierListenNode.yScale = _scaleH;
        [self addChild:_ChandelierListenNode];
        
        [_listen stop];
    }
    
    else if(CGRectContainsPoint(exitButton, location)){
        if(err){
            NSLog(@"Cannot load audio.");
        }
        else{
            [_player play];
            NSLog(@"Back clicked!");
            SKScene *mainMenu = [MainMenu sceneWithSize:self.size];
            mainMenu.scaleMode = SKSceneScaleModeAspectFill;
            
            [self.view presentScene:mainMenu transition:[SKTransition fadeWithDuration:1.5f]];
        }
    }
    
    else if (CGRectContainsPoint(CustomSong, location)){
        _cusSongState = 1;
        [_player play];
        [self addChild:_customSongOvr];
        [self.view addSubview:_textField];
    }
    }
    else{
        
        CGRect exitCusSong = CGRectMake(337, 320-198, 83, 23);
       
        
        if (CGRectContainsPoint(exitCusSong, location)){
            _cusSongState = 0;
            [_player play];
            [_customSongOvr removeFromParent];
            [_textField removeFromSuperview];
        }
        
    }
    }
    
    else if(fileNotFound == 1){
        CGRect retry = CGRectMake(242, 320-198, 84, 22);

        if (CGRectContainsPoint(retry, location)){
            NSLog(@"FOF");
            fileNotFound = 0;
            [_player play];
            _textField.text = @"";
            [self.view addSubview:_textField];
            [FileNotFound removeFromParent];
        }
    }
}

@end
