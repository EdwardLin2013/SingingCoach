//
//  AudioController.mm
//  TheSingingCoach
//
//  Created by Edward and Natalie on 22/7/14.
//  Copyright (c) 2014 Edward and Natalie. All rights reserved.
//
#import "AudioController.h"

struct CallbackData {
    AudioUnit                             rioUnit;
    BufferManager*                        bufferManager;
    DCRejectionFilter*                    dcRejectionFilter;
    BOOL*                                 muteAudio;
    BOOL*                                 audioChainIsBeingReconstructed;
    AudioFileID                           OriginalFile;
    AudioFileID                           FramesFile;
    SInt64                                currentIdxOriginal;
    SInt64                                currentIdxFrames;
    BOOL*                                 isRecording;
    
    CallbackData(): rioUnit(NULL), bufferManager(NULL), muteAudio(NULL), audioChainIsBeingReconstructed(NULL) {}
} cd;

// Render callback function
static OSStatus	performRender (void                         *inRefCon,
                               AudioUnitRenderActionFlags 	*ioActionFlags,
                               const AudioTimeStamp 		*inTimeStamp,
                               UInt32 						inBusNumber,
                               UInt32 						inNumberFrames,
                               AudioBufferList              *ioData)
{
    OSStatus err = noErr;
    if (*cd.audioChainIsBeingReconstructed == NO)
    {
        // we are calling AudioUnitRender on the input bus of AURemoteIO
        // this will store the audio data captured by the microphone in ioData
        err = AudioUnitRender(cd.rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
        
        // filter out the DC component of the signal
        cd.dcRejectionFilter->ProcessInplace((Float32*) ioData->mBuffers[0].mData, inNumberFrames);
        
        // fill up the audioDataBuffer
        cd.bufferManager->CopyAudioDataToBuffer((Float32*)ioData->mBuffers[0].mData, inNumberFrames);
        
        // Do the recording if needed
        if (cd.isRecording)
        {
            if (inNumberFrames > 0)
            {
                // write packets to file
                err = AudioFileWritePackets(cd.OriginalFile, FALSE, inNumberFrames, NULL, cd.currentIdxOriginal, &inNumberFrames, ioData->mBuffers[0].mData);
                cd.currentIdxOriginal += inNumberFrames;
                //NSLog(@"cd.currentIdxOriginal: %lld", cd.currentIdxOriginal);
            }
        }
        
        // mute audio if needed....mute the echo?
        for (UInt32 i=0; i<ioData->mNumberBuffers; ++i)
            memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
    }
    
    return err;
}

@implementation AudioController

/* -----------------------------Public Methods--------------------------------- Begin */
- (id)init:(UInt32)NewSampleRate FrameSize:(UInt32)NewFrameSize OverLap:(Float32)NewOverlap
{
    if (self = [super init])
    {
        _bufferManager = NULL;
        _dcRejectionFilter = NULL;
        
        _sampleRate = NewSampleRate;
        _framesSize = NewFrameSize;
        _Overlap = NewOverlap;
        
        _frequency = 0;
        _midiNum = 0;
        _pitch = @"nil";
        
        _pitchEstimatedScheduler = NULL;
        
        _Hz120 = floor(120*(float)_framesSize/(float)_sampleRate);
        _Hz530 = floor(530*(float)_framesSize/(float)_sampleRate);
        _Hz1100 = floor(1100*(float)_framesSize/(float)_sampleRate);
        
        _isRecording = NO;
        _FileNameOriginal = @"audioOriginal.wav";
        _FileNameFrames = @"audioFrames.wav";
        
        // Only connect to microphone
        [self setupAudioChain];
        
        NSError *error;
        _fileMgr = [NSFileManager defaultManager];

        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
        _docsDir =dirPaths[0];
        _tmpDir = NSTemporaryDirectory();
        NSLog(@"tmpDir:%@ directory content:%@",_tmpDir, [_fileMgr contentsOfDirectoryAtPath:_tmpDir error:&error]);
        NSLog(@"documentDir:%@ directory content:%@",_docsDir, [_fileMgr contentsOfDirectoryAtPath:_docsDir error:&error]);
    }
    return self;
}
- (OSStatus)startIOUnit
{
    _bufferManager = new BufferManager(_framesSize, _sampleRate, _Overlap);
    _dcRejectionFilter = new DCRejectionFilter;
    
    // We need references to certain data in the render callback
    // This simple struct is used to hold that information
    
    cd.rioUnit = _rioUnit;
    cd.bufferManager = _bufferManager;
    cd.dcRejectionFilter = _dcRejectionFilter;
    cd.audioChainIsBeingReconstructed = &_audioChainIsBeingReconstructed;
    
    OSStatus err = AudioOutputUnitStart(_rioUnit);
    if (err) NSLog(@"couldn't start AURemoteIO: %d", (int)err);
    
    NSTimeInterval interval = (double)(((1-_Overlap)*(Float32)_framesSize)/(Float32)_sampleRate);
    
    // Also start the Pitch Estimation
    _pitchEstimatedScheduler = [NSTimer scheduledTimerWithTimeInterval:interval
                                                                target:self
                                                              selector:@selector(EstimatePitch)
                                                              userInfo:nil
                                                               repeats:YES];
    
    return err;
}
- (OSStatus)stopIOUnit
{
    // Stop the Pitch Estimation
    if (_pitchEstimatedScheduler != NULL)
    {
        [_pitchEstimatedScheduler invalidate];
        _pitchEstimatedScheduler = NULL;
    }
    
    OSStatus err = AudioOutputUnitStop(_rioUnit);
    if (err) NSLog(@"couldn't stop AURemoteIO: %d", (int)err);
    
    delete _bufferManager;  _bufferManager = NULL;
    delete _dcRejectionFilter; _dcRejectionFilter = NULL;

    return err;
}
- (void)EstimatePitch
{
    if (_bufferManager != NULL)
    {
        if(_bufferManager->HasNewFFTData())
        {
            Float32 fftData[_framesSize];
            Float32 cepstrumData[_framesSize];
            Float32 fftlogcepstrumData[_framesSize];
            Float32 _curAmp;
            
            [self GetFFTOutput:fftData];
            _bufferManager->GetCepstrumOutput(fftData, cepstrumData);
            _bufferManager->GetFFTLogCepstrumOutput(fftData, cepstrumData, fftlogcepstrumData);
            
            Float32 _maxAmp = -INFINITY;
            int _bin = _Hz120;
            for (int i=_Hz120; i<=_Hz1100; i++)
            {
                _curAmp = fftlogcepstrumData[i];
                if (_curAmp > _maxAmp)
                {
                    _maxAmp = _curAmp;
                    _bin = i;
                }
            }
            
            _frequency = _bin*((float)_sampleRate/(float)_framesSize);
            _midiNum = [self freqToMIDI:_frequency];
            _pitch = [self midiToPitch:_midiNum];
            //NSLog(@"Current: %.12f %d %.12f %@", _frequency, _bin, _midiNum, _pitch);
        }
    }
}
- (NSString*)CurrentPitch
{
    return _pitch;
}
- (UInt32)getFrameSize
{
    return _framesSize;
}
- (double)sessionSampleRate
{
    return [[AVAudioSession sharedInstance] sampleRate];
}
- (BOOL)audioChainIsBeingReconstructed
{
    return _audioChainIsBeingReconstructed;
}
/* -----------------------------Public Methods--------------------------------- End */

/* -----------------------------Private Methods--------------------------------- Begin */
- (void)setupAudioChain
{
    [self setupAudioSession];
    [self setupIOUnit];
}
- (void)setupAudioSession
{
    try
    {
        // Configure the audio session
        AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
        
        // we are going to play and record so we pick that category
        NSError *error = nil;
        [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session's audio category");
        
        // set the buffer duration to 5 ms
        NSTimeInterval bufferDuration = .005;
        [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session's I/O buffer duration");
        
        // set the session's sample rate
        [sessionInstance setPreferredSampleRate:_sampleRate error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session's preferred sample rate");
        
        // add interruption handler
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:sessionInstance];
        
        // we don't do anything special in the route change notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRouteChange:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:sessionInstance];
        
        // if media services are reset, we need to rebuild our audio chain
        [[NSNotificationCenter defaultCenter]	addObserver:self
                                                 selector:@selector(handleMediaServerReset:)
                                                     name:AVAudioSessionMediaServicesWereResetNotification
                                                   object:sessionInstance];
        
        // activate the audio session
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session active");
    }
    catch (CAXException &e)
    {
        NSLog(@"Error returned from setupAudioSession: %d: %s", (int)e.mError, e.mOperation);
    }
    catch (...)
    {
        NSLog(@"Unknown error returned from setupAudioSession");
    }
    
    return;
}
- (void)setupIOUnit
{
    try
    {
        // Create a new instance of AURemoteIO
        AudioComponentDescription desc;
        desc.componentType = kAudioUnitType_Output;
        desc.componentSubType = kAudioUnitSubType_RemoteIO;
        desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        desc.componentFlags = 0;
        desc.componentFlagsMask = 0;
        
        AudioComponent comp = AudioComponentFindNext(NULL, &desc);
        XThrowIfError(AudioComponentInstanceNew(comp, &_rioUnit), "couldn't create a new instance of AURemoteIO");
        
        //  Enable input and output on AURemoteIO
        //  Input is enabled on the input scope of the input element
        //  Output is enabled on the output scope of the output element
        UInt32 one = 1;
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one)), "could not enable input on AURemoteIO");
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one)), "could not enable output on AURemoteIO");
        
        // Explicitly set the input and output client formats
        _ioFormat = CAStreamBasicDescription(_sampleRate, 1, CAStreamBasicDescription::kPCMFormatFloat32, false);
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &_ioFormat, sizeof(_ioFormat)), "couldn't set the input client format on AURemoteIO");
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &_ioFormat, sizeof(_ioFormat)), "couldn't set the output client format on AURemoteIO");
        
        // Set the MaximumFramesPerSlice property. This property is used to describe to an audio unit the maximum number
        // of samples it will be asked to produce on any single given call to AudioUnitRender
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &_framesSize, sizeof(UInt32)), "couldn't set max frames per slice on AURemoteIO");
        
        // Get the property value back from AURemoteIO. We are going to use this value to allocate buffers accordingly
        UInt32 propSize = sizeof(UInt32);
        XThrowIfError(AudioUnitGetProperty(_rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &_framesSize, &propSize), "couldn't get max frames per slice on AURemoteIO");
        
        // Set the render callback on AURemoteIO
        AURenderCallbackStruct renderCallback;
        renderCallback.inputProc = performRender;
        renderCallback.inputProcRefCon = NULL;
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, sizeof(renderCallback)), "couldn't set render callback on AURemoteIO");
        
        // Initialize the AURemoteIO instance
        XThrowIfError(AudioUnitInitialize(_rioUnit), "couldn't initialize AURemoteIO instance");
    }
    catch (CAXException &e)
    {
        NSLog(@"Error returned from setupIOUnit: %d: %s", (int)e.mError, e.mOperation);
    }
    catch (...)
    {
        NSLog(@"Unknown error returned from setupIOUnit");
    }
    
    return;
}


- (void)handleInterruption:(NSNotification *)notification
{
    try
    {
        UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
        NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
        
        if (theInterruptionType == AVAudioSessionInterruptionTypeBegan)
            [self stopIOUnit];
        
        if (theInterruptionType == AVAudioSessionInterruptionTypeEnded)
        {
            // make sure to activate the session
            NSError *error = nil;
            [[AVAudioSession sharedInstance] setActive:YES error:&error];
            if (nil != error) NSLog(@"AVAudioSession set active failed with error: %@", error);
            
            [self startIOUnit];
        }
    }
    catch (CAXException e)
    {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
    }
}
- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue)
    {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}
- (void)handleMediaServerReset:(NSNotification *)notification
{
    NSLog(@"Media server has reset");
    _audioChainIsBeingReconstructed = YES;
    
    usleep(25000); //wait here for some time to ensure that we don't delete these objects while they are being accessed elsewhere
    
    // rebuild the audio chain
    delete _bufferManager;      _bufferManager = NULL;
    delete _dcRejectionFilter;  _dcRejectionFilter = NULL;
    
    [self setupAudioChain];
    [self startIOUnit];
    
    _audioChainIsBeingReconstructed = NO;
}


- (void)startRecording
{
    if(!_isRecording)
    {
        // create the audio file
        NSString *filePathOriginal = [NSTemporaryDirectory() stringByAppendingPathComponent: _FileNameOriginal];
        NSString *filePathFrames = [NSTemporaryDirectory() stringByAppendingPathComponent: _FileNameFrames];
        
        CFURLRef urlOriginal = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filePathOriginal, kCFURLPOSIXPathStyle, false);
        CFURLRef urlFrames = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filePathFrames, kCFURLPOSIXPathStyle, false);
        NSLog(@"Start Recording");
        NSLog(@"Original at: %@", urlOriginal);
        NSLog(@"Frames at: %@", urlFrames);
        XThrowIfError(AudioFileCreateWithURL(urlOriginal, kAudioFileWAVEType, &_ioFormat, kAudioFileFlags_EraseFile, &_OriginalFile), "Original: AudioFileCreateWithURL failed");
        XThrowIfError(AudioFileCreateWithURL(urlFrames, kAudioFileWAVEType, &_ioFormat, kAudioFileFlags_EraseFile, &_FramesFile), "Frames: AudioFileCreateWithURL failed");
        CFRelease(urlOriginal);
        CFRelease(urlFrames);
        
        cd.OriginalFile = _OriginalFile;
        cd.FramesFile = _FramesFile;
        cd.currentIdxOriginal = 0;
        cd.currentIdxFrames = 0;
        _isRecording = YES;
        cd.isRecording = &_isRecording;
    }
}
- (void)stopRecording
{
    if(_isRecording)
    {
        NSLog(@"Stop Recording");
        
        _isRecording = NO;
        cd.isRecording = &_isRecording;
    }
}
- (BOOL)isRecording
{
    return _isRecording;
}
- (void)GetFFTOutput:(Float32*)outFFTData
{
    // Do the recording if needed
    if (_isRecording==YES && _bufferManager->HasNewFFTData())
    {
        Float32* fftData = _bufferManager->GetFFTBuffers();
        
        // write packets to file
        UInt32 inNumberFrames = _framesSize;
        XThrowIfError(AudioFileWritePackets(cd.FramesFile, FALSE, _framesSize, NULL, cd.currentIdxFrames, &inNumberFrames, fftData), "Cannot write data to FFTfile?");
        cd.currentIdxFrames += inNumberFrames;
        //NSLog(@"cd.currentIdxFrames: %lld", cd.currentIdxFrames);
        
        free(fftData); fftData = NULL;
    }
    else if(_isRecording==NO && cd.currentIdxFrames>0)
    {
        AudioFileClose(_OriginalFile);
        AudioFileClose(_FramesFile);
    }
    
    _bufferManager->GetFFTOutput(outFFTData);
}

- (Float32)freqToMIDI:(Float32)frequency
{
    if (frequency <=0)
        return -1;
    else
        return 12*log2f(frequency/440) + 69;
}
- (NSString*)midiToPitch:(Float32)midiNote
{
    if (midiNote<=-1)
        return @"NIL";
    
    int midi = (int)round((double)midiNote);
    NSArray *noteStrings = [[NSArray alloc] initWithObjects:@"C", @"C#", @"D", @"D#", @"E", @"F", @"F#", @"G", @"G#", @"A", @"A#", @"B", nil];
    NSString *retval = [noteStrings objectAtIndex:midi%12];
    
    if(midi <= 23)
        retval = [retval stringByAppendingString:@"0"];
    else if(midi <= 35)
        retval = [retval stringByAppendingString:@"1"];
    else if(midi <= 47)
        retval = [retval stringByAppendingString:@"2"];
    else if(midi <= 59)
        retval = [retval stringByAppendingString:@"3"];
    else if(midi <= 71)
        retval = [retval stringByAppendingString:@"4"];
    else if(midi <= 83)
        retval = [retval stringByAppendingString:@"5"];
    else if(midi <= 95)
        retval = [retval stringByAppendingString:@"6"];
    else if(midi <= 107)
        retval = [retval stringByAppendingString:@"7"];
    else
        retval = [retval stringByAppendingString:@"8"];
    
    return retval;
}

- (void)removeTmpFiles
{
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *tmpOriginalFile = [tmpDir stringByAppendingString:@"audioOriginal.wav"];
    NSString *tmpFramesFile = [tmpDir stringByAppendingString:@"audioFrames.wav"];
    
    if([fileMgr removeItemAtPath:tmpOriginalFile error:&error])
        NSLog(@"Yes, files are removed: %@", tmpOriginalFile);
    else
    {
        NSLog(@"No, files are removed: %@", tmpOriginalFile);
        NSLog(@"No, error is %@", error);
    }
    if([fileMgr removeItemAtPath:tmpFramesFile error:&error])
        NSLog(@"Yes, files are removed %@", tmpFramesFile);
    else
    {
        NSLog(@"No, files are removed: %@", tmpFramesFile);
        NSLog(@"No, error is %@", error);
    }
}

// Move the audio files from tmp directory to Document directory
- (void)saveRecording:(NSString *)SongName
{
    NSError* error;
    
    NSString *tmpOriginalFile = [_tmpDir stringByAppendingString:@"audioOriginal.wav"];
    NSString *tmpFramesFile = [_tmpDir stringByAppendingString:@"audioFrames.wav"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd_HHmm"];
    NSString *strNow = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *OriginalDocFileName = SongName;
    OriginalDocFileName = [OriginalDocFileName stringByAppendingString:@"_Original_"];
    OriginalDocFileName = [OriginalDocFileName stringByAppendingString:strNow];
    OriginalDocFileName = [OriginalDocFileName stringByAppendingString:@".wav"];
    NSString *FramesDocFileName = SongName;
    FramesDocFileName = [FramesDocFileName stringByAppendingString:@"_Frames_"];
    FramesDocFileName = [FramesDocFileName stringByAppendingString:strNow];
    FramesDocFileName = [FramesDocFileName stringByAppendingString:@".wav"];

    NSString *docOriginalFile = [_docsDir stringByAppendingString:@"/"];
    docOriginalFile = [docOriginalFile stringByAppendingString:OriginalDocFileName];
    NSString *docFramesFile = [_docsDir stringByAppendingString:@"/"];
    docFramesFile = [docFramesFile stringByAppendingString:FramesDocFileName];
    
    if([_fileMgr moveItemAtPath:tmpOriginalFile toPath:docOriginalFile error:&error])
        NSLog(@"Yes, files are moved to %@", docOriginalFile);
    else
    {
        NSLog(@"No, files are not moved to %@", docOriginalFile);
        NSLog(@"No, error is %@", error);
    }
    if([_fileMgr moveItemAtPath:tmpFramesFile toPath:docFramesFile error:&error])
        NSLog(@"Yes, files are moved to %@", docFramesFile);
    else
    {
        NSLog(@"No, files are not moved to %@", docFramesFile);
        NSLog(@"No, error is %@", error);
    }
}
/* -----------------------------Private Methods--------------------------------- Begin */

@end
