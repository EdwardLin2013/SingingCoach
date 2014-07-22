/*
 
     File: FFTHelper.cpp
 Abstract: This class demonstrates how to use the Accelerate framework to take Fast Fourier Transforms (FFT) of the audio data. FFTs are used to perform analysis on the captured audio data
 
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

#include "WaveFFTCepstrumHelper.h"

// Utility includes
#include "CABitOperations.h"

const Float32 kAdjust0DB = 1.5849e-13;

WaveFFTCepstrumHelper::WaveFFTCepstrumHelper ( UInt32 _framesSize ) :
_SpectrumAnalysis(NULL),
_FFTNormFactor(0.5),
_FFTLength(_framesSize/2),
_Log2N(Log2Ceil(_framesSize)),
_FrameSize(_framesSize)
{
    _DspSplitComplex.realp = (Float32*) calloc(_FFTLength, sizeof(Float32));
    _DspSplitComplex.imagp = (Float32*) calloc(_FFTLength, sizeof(Float32));
    _SpectrumAnalysis = vDSP_create_fftsetup(_Log2N, kFFTRadix2);
    
    _DspVector = (Float32*) calloc(_framesSize, sizeof(Float32));
    _logFFT = (Float32*) calloc(_framesSize, sizeof(Float32));
    _logCep = (Float32*) calloc(_framesSize, sizeof(Float32));
}
WaveFFTCepstrumHelper::~WaveFFTCepstrumHelper()
{
    vDSP_destroy_fftsetup(_SpectrumAnalysis);
    free (_DspSplitComplex.realp);
    free (_DspSplitComplex.imagp);

    free (_DspVector);
    free (_logFFT);
    free (_logCep);
}

/*
 *  Implement Matlab's abs(fft(inData))
 *  Size of inDate and outFFTData: __FrameSize
 */
void WaveFFTCepstrumHelper::ComputeABSFFT(Float32* inData, Float32* outFFTData)
{
	if (inData == NULL || outFFTData == NULL) return;
    
//    for (UInt32 i=0; i<_FrameSize; i++)
//        printf("inData[%ld]: %.12f\n", i, inData[i]);
    
    //Generate a split complex vector from the real data
    vDSP_ctoz((COMPLEX *)inData, 2, &_DspSplitComplex, 1, _FFTLength);
    
    //Take the fft and scale appropriately
    vDSP_fft_zrip(_SpectrumAnalysis, &_DspSplitComplex, 1, _Log2N, kFFTDirection_Forward);

    // Scale the fft result by 0.5
    _midReal = _DspSplitComplex.realp[_FFTLength];
    _midImag = _DspSplitComplex.imagp[_FFTLength];
    _midReal *= _FFTNormFactor;
    _midImag *= _FFTNormFactor;
    for (UInt32 i=0; i<_FFTLength; i++)
    {
        _DspSplitComplex.realp[i] *= _FFTNormFactor;
        _DspSplitComplex.imagp[i] *= _FFTNormFactor;
    }
    
    //Zero out the nyquist value
    _DspSplitComplex.imagp[0] = 0.0;
        
    //Convert the fft result: abs(fft)
    vDSP_zvabs(&_DspSplitComplex, 1, outFFTData, 1, _FFTLength);
    
    //Mirror the first half result
    for (UInt32 i=0; i<_FFTLength-1; i++)
        outFFTData[_FrameSize-1-i] = outFFTData[i+1];
    outFFTData[_FFTLength] = sqrtf((_midReal*_midReal) + (_midImag*_midImag));
    // FIXME: Should we do this?----
    if (outFFTData[_FFTLength]==0)
        outFFTData[_FFTLength] = kAdjust0DB;
    //------------------------------
    
//    for (UInt32 i=0; i<_FrameSize; i++)
//        printf("outFFTData[%ld]: %.12f\n", i, outFFTData[i]);
    
    // Clear the temporary storage
    memset(_DspSplitComplex.realp, 0, _FFTLength*sizeof(Float32));
    memset(_DspSplitComplex.imagp, 0, _FFTLength*sizeof(Float32));
}

/*
 *  Implement Matlab's abs(fft(log(inFFTData)))
 *  Size of inFFTData and outCepstrumData: __FrameSize
 */
void WaveFFTCepstrumHelper::ComputeCepstrum ( Float32* inFFTData, Float32* outCepstrumData )
{
	if (inFFTData == NULL || outCepstrumData == NULL) return;
    
    // Take the log of the FFT result
    for (UInt32 i=0; i<_FrameSize; i++)
        _DspVector[i] = logf(inFFTData[i]);
    
    // Do the FFT again
    ComputeABSFFT(_DspVector, outCepstrumData);
    
    // Clear the temporary storage
    memset(_DspVector, 0, _FrameSize*sizeof(Float32));
}
void WaveFFTCepstrumHelper::ComputeFFTCepstrum ( Float32* inFFTData, Float32* inCepstrumData, Float32* inFFTCepstrumData )
{
    // Suggest by Simon's PhD Thesis - Take a log of FFT and Cepstrum to sharpen its peak
    for (UInt32 i=0; i<_FrameSize; i++)
    {
        _logFFT[i] = logf(inFFTData[i]);
        _logCep[i] = logf(inCepstrumData[i]);
    }
    
    for (UInt32 i=0; i<_FrameSize; i++)
    {
        inFFTCepstrumData[i] = inFFTData[i]*_logCep[i];
        //inFFTCepstrumData[i] = _logFFT[i]*_logCep[i];
        //inFFTCepstrumData[i] = inFFTData[i]*inCepstrumData[i];
    }
    
    // Clear the temporary storage
    memset(_logFFT, 0, _FrameSize*sizeof(Float32));
    memset(_logCep, 0, _FrameSize*sizeof(Float32));
}