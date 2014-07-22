/*
 
     File: AudioController.mm
 Abstract: n/a
  Version: 2.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 
 */
#import "AudioController.h"

struct CallbackData {
    AudioUnit                             rioUnit;
    BufferManager*                        bufferManager;
    DCRejectionFilter*                    dcRejectionFilter;
    BOOL*                                 muteAudio;
    BOOL*                                 audioChainIsBeingReconstructed;
    AudioFileID                           WaveFile;
    AudioFileID                           FFTFile;
    SInt64                                currentFramesWave;
    SInt64                                currentFramesFFT;
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
        
        // fill up the buffer for Audio Wave
        cd.bufferManager->CopyAudioDataToWaveBuffer((Float32*)ioData->mBuffers[0].mData, inNumberFrames);
        
        // fill up the buffer for FFT
        if (cd.bufferManager->NeedsNewFFTData())
        {
            //cd.bufferManager->CopyAudioDataToFFTInputBuffer((Float32*)ioData->mBuffers[0].mData, inNumberFrames);
            cd.bufferManager->CopyAudioDataToFFTInputBufferVer2((Float32*)ioData->mBuffers[0].mData, inNumberFrames);
        }
        
        // Do the recording if needed
        if (cd.isRecording)
        {
            if (inNumberFrames > 0)
            {
                // write packets to file
                err = AudioFileWritePackets(cd.WaveFile, FALSE, inNumberFrames, NULL, cd.currentFramesWave, &inNumberFrames, ioData->mBuffers[0].mData);
                cd.currentFramesWave += inNumberFrames;
                //NSLog(@"cd.currentFramesWave: %lld", cd.currentFramesWave);
            }
        }
        
        // mute audio if needed....mute the echo?
        for (UInt32 i=0; i<ioData->mNumberBuffers; ++i)
            memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
    }
    
    return err;
}

@implementation AudioController

- (id)init:(UInt32)NewSampleRate FrameSize:(UInt32)NewFrameSize
{
    if (self = [super init])
    {
        _bufferManager = NULL;
        _dcRejectionFilter = NULL;
        
        _sampleRate = NewSampleRate;
        _framesSize = NewFrameSize;
        
        _isRecording = NO;
        _FileNameWave = @"audioWave.wav";
        _FileNameFFT = @"audioFFT.wav";
        
        [self setupAudioChain];
    }
    return self;
}


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
        
        _bufferManager = new BufferManager(_framesSize);
        _dcRejectionFilter = new DCRejectionFilter;
        
        // We need references to certain data in the render callback
        // This simple struct is used to hold that information
        
        cd.rioUnit = _rioUnit;
        cd.bufferManager = _bufferManager;
        cd.dcRejectionFilter = _dcRejectionFilter;
        cd.audioChainIsBeingReconstructed = &_audioChainIsBeingReconstructed;
        
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

- (OSStatus)startIOUnit
{
    OSStatus err = AudioOutputUnitStart(_rioUnit);
    if (err) NSLog(@"couldn't start AURemoteIO: %d", (int)err);
    return err;
}
- (OSStatus)stopIOUnit
{
    OSStatus err = AudioOutputUnitStop(_rioUnit);
    if (err) NSLog(@"couldn't stop AURemoteIO: %d", (int)err);
    return err;
}

- (BufferManager*)getBufferManagerInstance
{
    return _bufferManager;
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

- (void)startRecording
{
    if(!_isRecording)
    {
        // create the audio file
        NSString *filePathWave = [NSHomeDirectory() stringByAppendingPathComponent: _FileNameWave];
        NSString *filePathFFT = [NSHomeDirectory() stringByAppendingPathComponent: _FileNameFFT];
        
        CFURLRef urlWave = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filePathWave, kCFURLPOSIXPathStyle, false);
        CFURLRef urlFFT = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filePathFFT, kCFURLPOSIXPathStyle, false);
        NSLog(@"Start Recording");
        NSLog(@"Wave at: %@", urlWave);
        NSLog(@"FFT at: %@", urlFFT);
        XThrowIfError(AudioFileCreateWithURL(urlWave, kAudioFileWAVEType, &_ioFormat, kAudioFileFlags_EraseFile, &_WaveFile), "AudioFileCreateWithURL failed");
        XThrowIfError(AudioFileCreateWithURL(urlFFT, kAudioFileWAVEType, &_ioFormat, kAudioFileFlags_EraseFile, &_FFTFile), "AudioFileCreateWithURL failed");
        CFRelease(urlWave);
        CFRelease(urlFFT);
        
        cd.WaveFile = _WaveFile;
        cd.FFTFile = _FFTFile;
        cd.currentFramesWave = 0;
        cd.currentFramesFFT = 0;
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
        const void* fftData = _bufferManager->GetFFTInputBuffers();
        
        // write packets to file
        UInt32 inNumberFrames = _framesSize;
        XThrowIfError(AudioFileWritePackets(cd.FFTFile, FALSE, _framesSize, NULL, cd.currentFramesFFT, &inNumberFrames, fftData), "Cannot write data to FFTfile?");
        cd.currentFramesFFT += inNumberFrames;
        //NSLog(@"cd.currentFramesFFT: %lld", cd.currentFramesFFT);
    }
    else if(_isRecording==NO && cd.currentFramesFFT>0)
    {
        AudioFileClose(_WaveFile);
        AudioFileClose(_FFTFile);
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
@end
