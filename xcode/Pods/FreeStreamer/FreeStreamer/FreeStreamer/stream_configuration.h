/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#ifndef ASTREAMER_STREAM_CONFIGURATION_H
#define ASTREAMER_STREAM_CONFIGURATION_H

#import <CoreFoundation/CoreFoundation.h>

namespace astreamer {
    
struct Stream_Configuration {
    unsigned bufferCount;
    unsigned bufferSize;
    unsigned maxPacketDescs;
    unsigned httpConnectionBufferSize;
    double outputSampleRate;
    long outputNumChannels;
    int bounceInterval;
    int maxBounceCount;
    int startupWatchdogPeriod;
    int maxPrebufferedByteCount;
    bool usePrebufferSizeCalculationInSeconds;
    bool usePrebufferSizeCalculationInPackets;
    int requiredInitialPrebufferedByteCountForContinuousStream;
    int requiredInitialPrebufferedByteCountForNonContinuousStream;
    int requiredPrebufferSizeInSeconds;
    int requiredInitialPrebufferedPacketCount;
    CFStringRef userAgent;
    CFStringRef cacheDirectory;
    CFDictionaryRef predefinedHttpHeaderValues;
    bool cacheEnabled;
    bool seekingFromCacheEnabled;
    bool automaticAudioSessionHandlingEnabled;
    bool enableTimeAndPitchConversion;
    bool requireStrictContentTypeChecking;
    int maxDiskCacheSize;
    
    static Stream_Configuration *configuration();
    
private:
    Stream_Configuration();
    ~Stream_Configuration();
    
    Stream_Configuration(const Stream_Configuration&);
    Stream_Configuration& operator=(const Stream_Configuration&);
};
    
} // namespace astreamer

#endif // ASTREAMER_STREAM_CONFIGURATION_H