/*
 
     File: BufferManager.h
 Abstract: This class handles buffering of audio data that is shared between the view and audio controller
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

#ifndef __aurioTouch3__BufferManager__
#define __aurioTouch3__BufferManager__

#include <AudioToolbox/AudioToolbox.h>
#include <libkern/OSAtomic.h>

#include "WaveFFTCepstrumHelper.h"


//const UInt32 kNumDrawBuffers = 12;
//const UInt32 kDefaultDrawSamples = 1024;
const UInt32 kNumDrawBuffers = 2;
//const UInt32 kDefaultDrawSamples = 4096;

class BufferManager
{
    public:
        BufferManager( UInt32 _framesSize );
        ~BufferManager();
    
        Float32**       GetWaveBuffers ()  { return _WaveBuffers; }
        void            CopyAudioDataToWaveBuffer( Float32* inData, UInt32 NewNumFrames );
        void            CycleWaveBuffers();
        void            SetWaveBufferLength ( UInt32 NewWaveBufferLen ) { _WaveBufferLen = NewWaveBufferLen; }
        UInt32          GetWaveBufferLength ()   { return _WaveBufferLen; }
    
    
        Float32**       GetFFTBuffers ()  { return _FFTBuffers; }
        Float32*        GetFFTInputBuffers ()  { return _FFTInputBuffer; }
        void            CopyAudioDataToFFTInputBuffer( Float32* inData, UInt32 NewNumFrames );
        void            CopyAudioDataToFFTInputBufferVer2( Float32* inData, UInt32 NewNumFrames );
        void            CycleFFTBuffers();
        void            SetFFTBufferLength ( UInt32 NewFFTBufferLen ) { _FFTBufferLen = NewFFTBufferLen; }
        UInt32          GetFFTBufferLength ()   { return _FFTBufferLen; }
    
        UInt32          GetFFTOutputBufferLength() { return _FFTInputBufferLen / 2; }
        void            GetFFTOutput ( Float32* outFFTData );
        void            GetCepstrumOutput ( Float32* inFFTData, Float32* outCepstrumData );
        void            GetFFTCepstrumOutput ( Float32* inFFTData, Float32* inCepstrumData, Float32* inFFTCepstrumData );

        bool            HasNewFFTData()     { return static_cast<bool>(_HasNewFFTData); };
        bool            NeedsNewFFTData()   { return static_cast<bool>(_NeedsNewFFTData); };
    
    private:
        Float32*                    _WaveBuffers[kNumDrawBuffers];
        UInt32                      _WaveBufferIndex;
        UInt32                      _WaveBufferLen;

        Float32*                    _FFTBuffers[kNumDrawBuffers];
        UInt32                      _FFTBufferIndex;
        UInt32                      _FFTBufferLen;
    
        Float32*                    _FFTInputBuffer;
        Float32*                    _FFTInputBuffer_Backup;
        bool                        _IsBackupEmpty;
        UInt32                      _FFTInputBufferFrameIndex;
        UInt32                      _FFTInputBufferLen;
        volatile int32_t            _HasNewFFTData;
        volatile int32_t            _NeedsNewFFTData;
        
        WaveFFTCepstrumHelper*      _WaveFFTCepstrumHelper;
};

#endif /* defined(__aurioTouch3__BufferManager__) */
