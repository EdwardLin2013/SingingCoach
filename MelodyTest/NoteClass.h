//
//  NoteClass.h
//  MelodyTest
//
//  Created by CrimsonLycans on 13/6/14.
//  Copyright (c) 2014 CrimsonLycans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@interface NoteClass : NSObject

{
    SKSpriteNode* _NoteShape;
    float _length;
    NSString* _pitch;
    float _yLocation;
    
}

-(id)initWithNote: (SKSpriteNode*)Note
        withPitch:(NSString*)pitch
       withLength:(float)length
     withLocation:(float)yLocation;

-(SKSpriteNode*) getNoteShape;
-(float)getLength;
-(NSString*)getPitch;
-(float)getyLocation;

@end
