//
//  NoteClass.m
//  MelodyTest
//
//  Created by CrimsonLycans on 13/6/14.
//  Copyright (c) 2014 CrimsonLycans. All rights reserved.
//

#import "NoteClass.h"

@implementation NoteClass

-(id)initWithNote: (SKSpriteNode*)Note
        withPitch:(NSString*)pitch
       withLength:(float)length
     withLocation:(float)yLocation
{
    
    _pitch = pitch;
    _NoteShape = Note;
    _length = length;
    _yLocation = yLocation;
    return self;
    
}

-(SKSpriteNode*) getNoteShape{
    return _NoteShape;
}
-(float)getLength{
    return _length;
}
-(NSString*)getPitch{
    return _pitch;
}
-(float)getyLocation{
    return _yLocation;
}


@end
