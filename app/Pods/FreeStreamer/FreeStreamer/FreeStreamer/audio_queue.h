/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2018 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#ifndef ASTREAMER_AUDIO_QUEUE_H
#define ASTREAMER_AUDIO_QUEUE_H

#include <AudioToolbox/AudioToolbox.h> /* AudioFileStreamID */

namespace astreamer {
    
class Audio_Queue_Delegate;
struct queued_packet;
	
class Audio_Queue {
public:
    Audio_Queue_Delegate *m_delegate;
    
    enum State {
        IDLE,
        RUNNING,
        PAUSED
    };
    
    Audio_Queue();
    virtual ~Audio_Queue();
    
    bool initialized();
    
    void init();
    
    // Notice: the queue blocks if it has no free buffers
    void handleAudioPackets(UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData, AudioStreamPacketDescription *inPacketDescriptions);
    
    void start();
    void pause();
    void stop(bool stopImmediately);
    void stop();
    
    float volume();
    
    void setVolume(float volume);
    void setPlayRate(float playRate);
    
    AudioTimeStamp currentTime();
    AudioQueueLevelMeterState levels();
	
private:
    Audio_Queue(const Audio_Queue&);
    Audio_Queue& operator=(const Audio_Queue&);
    
    State m_state;
    
    AudioQueueRef m_outAQ;                                           // the audio queue
    
    AudioQueueBufferRef *m_audioQueueBuffer;              // audio queue buffers
    AudioStreamPacketDescription *m_packetDescs; // packet descriptions for enqueuing audio
    
    UInt32 m_fillBufferIndex;                                        // the index of the audioQueueBuffer that is being filled
    UInt32 m_bytesFilled;                                            // how many bytes have been filled
    UInt32 m_packetsFilled;                                          // how many packets have been filled
    UInt32 m_buffersUsed;                                            // how many buffers are used
    
    bool m_audioQueueStarted;                                        // flag to indicate that the queue has been started
    bool *m_bufferInUse;                                  // flags to indicate that a buffer is still in use
    bool m_levelMeteringEnabled;
    
    pthread_mutex_t m_mutex;
    
    pthread_mutex_t m_bufferInUseMutex;
    pthread_cond_t m_bufferFreeCondition;
    
public:
    OSStatus m_lastError;
    AudioStreamBasicDescription m_streamDesc;
    float m_initialOutputVolume;

private:
    void cleanup();
    void setCookiesForStream(AudioFileStreamID inAudioFileStream);
    void setState(State state);
    void enqueueBuffer();
    
    static void audioQueueOutputCallback(void *inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
    static void audioQueueIsRunningCallback(void *inClientData, AudioQueueRef inAQ, AudioQueuePropertyID inID);
};
    
class Audio_Queue_Delegate {
public:
    virtual void audioQueueStateChanged(Audio_Queue::State state) = 0;
    virtual void audioQueueBuffersEmpty() = 0;
    virtual void audioQueueInitializationFailed() = 0;
    virtual void audioQueueFinishedPlayingPacket() = 0;
};

} // namespace astreamer

#endif // ASTREAMER_AUDIO_QUEUE_H
