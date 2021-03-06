//
//  WaveFFTCepstrumHelper.h
//  TheSingingCoach
//
//  Created by Edward and Natalie on 22/7/14.
//  Copyright (c) 2014 Edward and Natalie. All rights reserved.
//
#ifndef __WaveFFTCepstrumHelper__
#define __WaveFFTCepstrumHelper__

#include <Accelerate/Accelerate.h>

class WaveFFTCepstrumHelper
{
public:
    WaveFFTCepstrumHelper( UInt32 _framesSize );
    ~WaveFFTCepstrumHelper();
    
    void ComputeABSFFT ( Float32* inData, Float32* outFFTData );
    void ComputeCepstrum ( Float32* inData, Float32* outFFTData );
    void ComputeFFTLogCepstrum ( Float32* inFFTData, Float32* inCepstrumData, Float32* inFFTCepstrumData );
    
private:
    FFTSetup                    _SpectrumAnalysis;
    DSPSplitComplex             _DspSplitComplex;
    Float32*                    _DspVector;
    Float32*                    _logCep;
    Float32                     _FFTNormFactor;
    UInt32                      _FFTLength;
    UInt32                      _Log2N;
    UInt32                      _FrameSize;
};

#endif /* defined(__WaveFFTCepstrumHelper__) */
