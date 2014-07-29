//
//  DCRejectionFilter.cpp
//  TheSingingCoach
//
//  Created by Edward and Natalie on 22/7/14.
//  Copyright (c) 2014 Edward and Natalie. All rights reserved.
//
#include "DCRejectionFilter.h"

const Float32 kDefaultPoleDist = 0.975f;

DCRejectionFilter::DCRejectionFilter()
{
	mY1 = mX1 = 0;
}


DCRejectionFilter::~DCRejectionFilter()
{
}


void DCRejectionFilter::ProcessInplace(Float32* inData, UInt32 numFrames)
{
	for (UInt32 i=0; i < numFrames; i++)
	{
        Float32 xCurr = inData[i];
		inData[i] = inData[i] - mX1 + (kDefaultPoleDist * mY1);
        mX1 = xCurr;
        mY1 = inData[i];
	}
}
