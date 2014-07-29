//
//  NoteClass.mm
//  TheSingingCoach
//
//  Created by Natalie and Edward on 11/6/14.
//  Copyright (c) 2014 Natalie and Edward. All rights reserved.
//
#import "NoteClass.h"

@implementation NoteClass

-(id)initWithNote: (SKSpriteNode*)Note
        withPitch:(NSString*)pitch
       withLength:(float)length
     withLocation:(float)yLocation
{
    if (self = [super init])
    {
        _pitch = pitch;
        _NoteShape = Note;
        _length = length;
        _yLocation = yLocation;
    }
    
    return self;
}

-(SKSpriteNode*) getNoteShape
{
    return _NoteShape;
}
-(float)getLength
{
    return _length;
}
-(NSString*)getPitch
{
    return _pitch;
}
-(float)getyLocation
{
    return _yLocation;
}


@end
