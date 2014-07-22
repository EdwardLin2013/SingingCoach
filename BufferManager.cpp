/*
 
     File: BufferManager.cpp
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

#include "BufferManager.h"


#define min(x,y) (x < y) ? x : y


BufferManager::BufferManager( UInt32 _framesSize ) :
_WaveBuffers(),
_WaveBufferIndex(0),
_WaveBufferLen(_framesSize),
_FFTBuffers(),
_FFTBufferIndex(0),
_FFTBufferLen(_framesSize),
_FFTInputBuffer(NULL),
_FFTInputBufferFrameIndex(0),
_FFTInputBufferLen(_framesSize),
_IsBackupEmpty(true),
_HasNewFFTData(0),
_NeedsNewFFTData(0),
_WaveFFTCepstrumHelper(NULL)
{
    for(UInt32 i=0; i<kNumDrawBuffers; ++i)
    {
        _WaveBuffers[i] = (Float32*) calloc(_framesSize, sizeof(Float32));
        _FFTBuffers[i] = (Float32*) calloc(_framesSize, sizeof(Float32));
    }
    
    _FFTInputBuffer = (Float32*) calloc(_framesSize, sizeof(Float32));
    _FFTInputBuffer_Backup = (Float32*) calloc(_framesSize, sizeof(Float32));
    _WaveFFTCepstrumHelper = new WaveFFTCepstrumHelper(_framesSize);
    OSAtomicIncrement32Barrier(&_NeedsNewFFTData);
}
BufferManager::~BufferManager()
{
    for(UInt32 i=0; i<kNumDrawBuffers; ++i)
    {
        free(_WaveBuffers[i]);
        _WaveBuffers[i] = NULL;
        
        free(_FFTBuffers[i]);
        _FFTBuffers[i] = NULL;
    }
    
    free(_FFTInputBuffer);
    delete _WaveFFTCepstrumHelper;
    _WaveFFTCepstrumHelper = NULL;
}


void BufferManager::CopyAudioDataToWaveBuffer( Float32* inData, UInt32 NewNumFrames )
{
    if (inData == NULL) return;
    
    for (UInt32 i=0; i<NewNumFrames; i++)
    {
        if ((i+_WaveBufferIndex) >= _WaveBufferLen)
        {
            CycleWaveBuffers();
            _WaveBufferIndex = -i;
        }
        _WaveBuffers[0][i + _WaveBufferIndex] = inData[i];
    }
    _WaveBufferIndex += NewNumFrames;
}
void BufferManager::CycleWaveBuffers()
{
    // Cycle the lines in our draw buffer so that they age and fade. The oldest line is discarded.
	for (int i=(kNumDrawBuffers - 2); i>=0; i--)
		memmove(_WaveBuffers[i + 1], _WaveBuffers[i], _WaveBufferLen);
}


void BufferManager::CopyAudioDataToFFTInputBuffer( Float32* inData, UInt32 NewNumFrames )
{
    UInt32 framesToCopy = min(NewNumFrames, _FFTInputBufferLen - _FFTInputBufferFrameIndex);
    
    //memcpy(_FFTInputBuffer + _FFTInputBufferFrameIndex, inData, framesToCopy * sizeof(Float32));
    //_FFTInputBufferFrameIndex += framesToCopy * sizeof(Float32);
    
    memcpy(_FFTInputBuffer + _FFTInputBufferFrameIndex, inData, framesToCopy);
    _FFTInputBufferFrameIndex += framesToCopy;
    
    if (_FFTInputBufferFrameIndex >= _FFTInputBufferLen)
    {
        OSAtomicIncrement32(&_HasNewFFTData);
        OSAtomicDecrement32(&_NeedsNewFFTData);
    }
}
void BufferManager::CopyAudioDataToFFTInputBufferVer2( Float32* inData, UInt32 NewNumFrames )
{
    UInt32 i=0;
    
    // If there is previous remaining data, add them to FFTInputBuffer first
    if (!_IsBackupEmpty)
    {
        for (i=0; i<_FFTInputBufferFrameIndex; i++)
            _FFTInputBuffer[i] = _FFTInputBuffer_Backup[i];
        
        _IsBackupEmpty = true;
    }
    
    UInt32 remainData = _FFTInputBufferLen - _FFTInputBufferFrameIndex;
    UInt32 framesToCopy = min(NewNumFrames, _FFTInputBufferLen - _FFTInputBufferFrameIndex);
    
    for (i=0; i<framesToCopy; i++)
        _FFTInputBuffer[i+_FFTInputBufferFrameIndex] = inData[i];
    _FFTInputBufferFrameIndex += framesToCopy;
    
    if (_FFTInputBufferFrameIndex >= _FFTInputBufferLen)
    {
        OSAtomicIncrement32(&_HasNewFFTData);
        OSAtomicDecrement32(&_NeedsNewFFTData);
    }
    
    // If there is any remaining data, then store them
    if (remainData < NewNumFrames)
    {
        remainData = NewNumFrames - remainData;
        
        for (i=0; i<remainData; i++)
            _FFTInputBuffer_Backup[i] = inData[framesToCopy+i];
        
        _FFTInputBufferFrameIndex = remainData;
        _IsBackupEmpty = false;
    }
}
void BufferManager::CycleFFTBuffers()
{
    // Cycle the lines in our draw buffer so that they age and fade. The oldest line is discarded.
	for (int i=(kNumDrawBuffers - 2); i>=0; i--)
		memmove(_FFTBuffers[i + 1], _FFTBuffers[i], _FFTBufferLen);
}
void BufferManager::GetFFTOutput( Float32* outFFTData )
{
    _WaveFFTCepstrumHelper->ComputeABSFFT(_FFTInputBuffer, outFFTData);
    _FFTInputBufferFrameIndex = 0;
    
    OSAtomicDecrement32Barrier(&_HasNewFFTData);
    OSAtomicIncrement32Barrier(&_NeedsNewFFTData);
}
void BufferManager::GetCepstrumOutput ( Float32* inFFTData, Float32* outCepstrumData )
{
    _WaveFFTCepstrumHelper->ComputeCepstrum(inFFTData, outCepstrumData);
}
void BufferManager::GetFFTCepstrumOutput ( Float32* inFFTData, Float32* inCepstrumData, Float32* inFFTCepstrumData )
{
    _WaveFFTCepstrumHelper->ComputeFFTCepstrum(inFFTData, inCepstrumData, inFFTCepstrumData);
}