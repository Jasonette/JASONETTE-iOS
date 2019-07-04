/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#include "audio_queue.h"
#include "stream_configuration.h"

#include <pthread.h>

//#define AQ_DEBUG 1
//#define AQ_DEBUG_LOCKS 1

#if !defined (AQ_DEBUG)
    #define AQ_TRACE(...) do {} while (0)
    #define AQ_ASSERT(...) do {} while (0)
#else
    #include <cassert>

    #define AQ_TRACE(...) printf(__VA_ARGS__)
    #define AQ_ASSERT(...) assert(__VA_ARGS__)
#endif

#if !defined (AQ_DEBUG_LOCKS)
#define AQ_LOCK_TRACE(...) do {} while (0)
#else
#define AQ_LOCK_TRACE(...) printf(__VA_ARGS__)
#endif


namespace astreamer {
    
/* public */    
    
Audio_Queue::Audio_Queue()
    : m_delegate(0),
    m_state(IDLE),
    m_outAQ(0),
    m_fillBufferIndex(0),
    m_bytesFilled(0),
    m_packetsFilled(0),
    m_buffersUsed(0),
    m_audioQueueStarted(false),
    m_levelMeteringEnabled(false),
    m_lastError(noErr),
    m_initialOutputVolume(1.0)
{
    Stream_Configuration *config = Stream_Configuration::configuration();
    
    m_audioQueueBuffer = new AudioQueueBufferRef[config->bufferCount];
    m_packetDescs = new AudioStreamPacketDescription[config->maxPacketDescs];
    m_bufferInUse = new bool[config->bufferCount];
    
    for (size_t i=0; i < config->bufferCount; i++) {
        m_bufferInUse[i] = false;
    }
    
    if (pthread_mutex_init(&m_mutex, NULL) != 0) {
        AQ_TRACE("m_mutex init failed!\n");
    }
    
    if (pthread_mutex_init(&m_bufferInUseMutex, NULL) != 0) {
        AQ_TRACE("m_bufferInUseMutex init failed!\n");
    }
    
    if (pthread_cond_init(&m_bufferFreeCondition, NULL) != 0) {
        AQ_TRACE("m_bufferFreeCondition init failed!\n");
    }
}
    
Audio_Queue::~Audio_Queue()
{
    stop(true);
    
    cleanup();
    
    delete [] m_audioQueueBuffer;
    delete [] m_packetDescs;
    delete [] m_bufferInUse;
    
    pthread_mutex_destroy(&m_mutex);
    pthread_mutex_destroy(&m_bufferInUseMutex);
    pthread_cond_destroy(&m_bufferFreeCondition);
}
    
bool Audio_Queue::initialized()
{
    return (m_outAQ != 0);
}
    
void Audio_Queue::start()
{
    // start the queue if it has not been started already
    if (m_audioQueueStarted) {
        return;
    }
            
    OSStatus err = AudioQueueStart(m_outAQ, NULL);
    if (!err) {
        m_audioQueueStarted = true;
        m_levelMeteringEnabled = false;
        m_lastError = noErr;
    } else {
        AQ_TRACE("%s: AudioQueueStart failed!\n", __PRETTY_FUNCTION__);
        m_lastError = err;
    }
}
    
void Audio_Queue::pause()
{
    if (m_state == RUNNING) {
        if (AudioQueuePause(m_outAQ) != 0) {
            AQ_TRACE("%s: AudioQueuePause failed!\n", __PRETTY_FUNCTION__);
        }
        setState(PAUSED);
    } else if (m_state == PAUSED) {
        AudioQueueStart(m_outAQ, NULL);
        setState(RUNNING);
    }
}
    
void Audio_Queue::stop()
{
    stop(true);
}
    
float Audio_Queue::volume()
{
    if (!m_outAQ) {
        return 1.0;
    }
    
    float vol;
    
    OSStatus err = AudioQueueGetParameter(m_outAQ, kAudioQueueParam_Volume, &vol);
    
    if (!err) {
        return vol;
    }
    
    return 1.0;
}
    
void Audio_Queue::setVolume(float volume)
{
    if (!m_outAQ) {
        return;
    }
    AudioQueueSetParameter(m_outAQ, kAudioQueueParam_Volume, volume);
}
    
void Audio_Queue::setPlayRate(float playRate)
{
    Stream_Configuration *configuration = Stream_Configuration::configuration();
    
    if (!configuration->enableTimeAndPitchConversion) {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
        printf("*** FreeStreamer notification: Trying to set play rate for audio queue but enableTimeAndPitchConversion is disabled from configuration. Play rate settign will not work.\n");
#endif
        return;
    }
    
    if (!m_outAQ) {
        return;
    }

    if (playRate < 0.5) {
        playRate = 0.5;
    }
    if (playRate > 2.0) {
        playRate = 2.0;
    }
    
    AudioQueueSetParameter(m_outAQ, kAudioQueueParam_PlayRate, playRate);
}

void Audio_Queue::stop(bool stopImmediately)
{
    if (!m_audioQueueStarted) {
        AQ_TRACE("%s: audio queue already stopped, return!\n", __PRETTY_FUNCTION__);
        return;
    }
    m_audioQueueStarted = false;
    m_levelMeteringEnabled = false;
    
    pthread_mutex_lock(&m_bufferInUseMutex);
    pthread_cond_signal(&m_bufferFreeCondition);
    pthread_mutex_unlock(&m_bufferInUseMutex);
    
    AQ_TRACE("%s: enter\n", __PRETTY_FUNCTION__);

    if (AudioQueueFlush(m_outAQ) != 0) {
        AQ_TRACE("%s: AudioQueueFlush failed!\n", __PRETTY_FUNCTION__);
    }
    
    if (stopImmediately) {
        AudioQueueRemovePropertyListener(m_outAQ,
                                         kAudioQueueProperty_IsRunning,
                                         audioQueueIsRunningCallback,
                                         this);
    }
    
    if (AudioQueueStop(m_outAQ, stopImmediately) != 0) {
        AQ_TRACE("%s: AudioQueueStop failed!\n", __PRETTY_FUNCTION__);
    }
    
    if (stopImmediately) {
        setState(IDLE);
    }
    
    AQ_TRACE("%s: leave\n", __PRETTY_FUNCTION__);
}
    
AudioTimeStamp Audio_Queue::currentTime()
{
    AudioTimeStamp queueTime;
    Boolean discontinuity;
    
    memset(&queueTime, 0, sizeof queueTime);
    
    OSStatus err = AudioQueueGetCurrentTime(m_outAQ, NULL, &queueTime, &discontinuity);
    if (err) {
        AQ_TRACE("AudioQueueGetCurrentTime failed\n");
    }
    
    return queueTime;
}

AudioQueueLevelMeterState Audio_Queue::levels()
{
    if (!m_levelMeteringEnabled) {
        UInt32 enabledLevelMeter = true;
        AudioQueueSetProperty(m_outAQ,
                              kAudioQueueProperty_EnableLevelMetering,
                              &enabledLevelMeter,
                              sizeof(UInt32));
        
        m_levelMeteringEnabled = true;
    }
    
    AudioQueueLevelMeterState levelMeter;
    UInt32 levelMeterSize = sizeof(AudioQueueLevelMeterState);
    AudioQueueGetProperty(m_outAQ, kAudioQueueProperty_CurrentLevelMeterDB, &levelMeter, &levelMeterSize);
    return levelMeter;
}
    
void Audio_Queue::init()
{
    OSStatus err = noErr;
    
    cleanup();
        
    // create the audio queue
    err = AudioQueueNewOutput(&m_streamDesc, audioQueueOutputCallback, this, CFRunLoopGetCurrent(), NULL, 0, &m_outAQ);
    if (err) {
        AQ_TRACE("%s: error in AudioQueueNewOutput\n", __PRETTY_FUNCTION__);
        
        m_lastError = err;
        
        if (m_delegate) {
            m_delegate->audioQueueInitializationFailed();
        }
        
        return;
    }
    
    Stream_Configuration *configuration = Stream_Configuration::configuration();
    
    // allocate audio queue buffers
    for (unsigned int i = 0; i < configuration->bufferCount; ++i) {
        err = AudioQueueAllocateBuffer(m_outAQ, configuration->bufferSize, &m_audioQueueBuffer[i]);
        if (err) {
            /* If allocating the buffers failed, everything else will fail, too.
             *  Dispose the queue so that we can later on detect that this
             *  queue in fact has not been initialized.
             */
            
            AQ_TRACE("%s: error in AudioQueueAllocateBuffer\n", __PRETTY_FUNCTION__);
            
            (void)AudioQueueDispose(m_outAQ, true);
            m_outAQ = 0;
            
            m_lastError = err;
            
            if (m_delegate) {
                m_delegate->audioQueueInitializationFailed();
            }
            
            return;
        }
    }
    
    // listen for kAudioQueueProperty_IsRunning
    err = AudioQueueAddPropertyListener(m_outAQ, kAudioQueueProperty_IsRunning, audioQueueIsRunningCallback, this);
    if (err) {
        AQ_TRACE("%s: error in AudioQueueAddPropertyListener\n", __PRETTY_FUNCTION__);
        m_lastError = err;
        return;
    }
    
    if (configuration->enableTimeAndPitchConversion) {
        UInt32 enableTimePitchConversion = 1;
        
        err = AudioQueueSetProperty (m_outAQ, kAudioQueueProperty_EnableTimePitch, &enableTimePitchConversion, sizeof(enableTimePitchConversion));
        if (err != noErr) {
            AQ_TRACE("Failed to enable time and pitch conversion. Play rate setting will fail\n");
        }
    }
    
    if (m_initialOutputVolume != 1.0) {
        setVolume(m_initialOutputVolume);
    }
}

void Audio_Queue::handleAudioPackets(UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData, AudioStreamPacketDescription *inPacketDescriptions)
{
    if (!initialized()) {
        AQ_TRACE("%s: warning: attempt to handle audio packets with uninitialized audio queue. return.\n", __PRETTY_FUNCTION__);
        
        return;
    }
    
    // this is called by audio file stream when it finds packets of audio
    AQ_TRACE("got data.  bytes: %u  packets: %u\n", inNumberBytes, (unsigned int)inNumberPackets);
    
    /* Place each packet into a buffer and then send each buffer into the audio
     queue */
    UInt32 i;
    
    for (i = 0; i < inNumberPackets; i++) {
        AudioStreamPacketDescription *desc = &inPacketDescriptions[i];
        
        const void *data = (const char*)inInputData + desc->mStartOffset;
        
        if (!initialized()) {
            AQ_TRACE("%s: warning: attempt to handle audio packets with uninitialized audio queue. return.\n", __PRETTY_FUNCTION__);
            
            return;
        }
        
        Stream_Configuration *config = Stream_Configuration::configuration();
        
        AQ_TRACE("%s: enter\n", __PRETTY_FUNCTION__);
        
        UInt32 packetSize = desc->mDataByteSize;
        
        /* This shouldn't happen because most of the time we read the packet buffer
         size from the file stream, but if we restored to guessing it we could
         come up too small here */
        if (packetSize > config->bufferSize) {
            AQ_TRACE("%s: packetSize %u > AQ_BUFSIZ %li\n", __PRETTY_FUNCTION__, (unsigned int)packetSize, config->bufferSize);
            return;
        }
        
        // if the space remaining in the buffer is not enough for this packet, then
        // enqueue the buffer and wait for another to become available.
        if (config->bufferSize - m_bytesFilled < packetSize) {
            enqueueBuffer();
            
            if (!m_audioQueueStarted) {
                return;
            }
        } else {
            AQ_TRACE("%s: skipped enqueueBuffer AQ_BUFSIZ - m_bytesFilled %lu, packetSize %u\n", __PRETTY_FUNCTION__, (config->bufferSize - m_bytesFilled), (unsigned int)packetSize);
        }
        
        // copy data to the audio queue buffer
        AudioQueueBufferRef buf = m_audioQueueBuffer[m_fillBufferIndex];
        memcpy((char*)buf->mAudioData, data, packetSize);
        
        // fill out packet description to pass to enqueue() later on
        m_packetDescs[m_packetsFilled] = *desc;
        // Make sure the offset is relative to the start of the audio buffer
        m_packetDescs[m_packetsFilled].mStartOffset = m_bytesFilled;
        // keep track of bytes filled and packets filled
        m_bytesFilled += packetSize;
        m_packetsFilled++;
        
        /* If filled our buffer with packets, then commit it to the system */
        if (m_packetsFilled >= config->maxPacketDescs) {
            enqueueBuffer();
        }
    }
}

/* private */
    
void Audio_Queue::cleanup()
{
    if (!initialized()) {
        AQ_TRACE("%s: warning: attempt to cleanup an uninitialized audio queue. return.\n", __PRETTY_FUNCTION__);
        
        return;
    }
    
    Stream_Configuration *config = Stream_Configuration::configuration();
    
    if (m_state != IDLE) {
        AQ_TRACE("%s: attemping to cleanup the audio queue when it is still playing, force stopping\n",
                 __PRETTY_FUNCTION__);
        
        AudioQueueRemovePropertyListener(m_outAQ,
                                         kAudioQueueProperty_IsRunning,
                                         audioQueueIsRunningCallback,
                                         this);
        
        AudioQueueStop(m_outAQ, true);
        setState(IDLE);
    }
    
    if (AudioQueueDispose(m_outAQ, true) != 0) {
        AQ_TRACE("%s: AudioQueueDispose failed!\n", __PRETTY_FUNCTION__);
    }
    m_outAQ = 0;
    m_fillBufferIndex = m_bytesFilled = m_packetsFilled = m_buffersUsed = 0;
    
    for (size_t i=0; i < config->bufferCount; i++) {
        m_bufferInUse[i] = false;
    }
    
    m_lastError = noErr;
}
    
void Audio_Queue::setState(State state)
{
    if (m_state == state) {
        /* We are already in this state! */
        return;
    }
    
    m_state = state;
    
    if (m_delegate) {
        m_delegate->audioQueueStateChanged(m_state);
    }
}

void Audio_Queue::enqueueBuffer()
{
    AQ_ASSERT(!m_bufferInUse[m_fillBufferIndex]);
    
    Stream_Configuration *config = Stream_Configuration::configuration();
    
    AQ_TRACE("%s: enter\n", __PRETTY_FUNCTION__);
    
    pthread_mutex_lock(&m_bufferInUseMutex);
    
    m_bufferInUse[m_fillBufferIndex] = true;
    m_buffersUsed++;
    
    // enqueue buffer
    AudioQueueBufferRef fillBuf = m_audioQueueBuffer[m_fillBufferIndex];
    fillBuf->mAudioDataByteSize = m_bytesFilled;
    
    pthread_mutex_unlock(&m_bufferInUseMutex);
    
    AQ_ASSERT(m_packetsFilled > 0);
    OSStatus err = AudioQueueEnqueueBuffer(m_outAQ, fillBuf, m_packetsFilled, m_packetDescs);
    
    if (!err) {
        m_lastError = noErr;
        start();
    } else {
        /* If we get an error here, it very likely means that the audio queue is no longer
           running */
        AQ_TRACE("%s: error in AudioQueueEnqueueBuffer\n", __PRETTY_FUNCTION__);
        m_lastError = err;
        return;
    }
    
    pthread_mutex_lock(&m_bufferInUseMutex);
    // go to next buffer
    if (++m_fillBufferIndex >= config->bufferCount) {
        m_fillBufferIndex = 0; 
    }
    // reset bytes filled
    m_bytesFilled = 0;
    // reset packets filled
    m_packetsFilled = 0;
    
    // wait until next buffer is not in use
    
    while (m_bufferInUse[m_fillBufferIndex]) {
        AQ_TRACE("waiting for buffer %u\n", (unsigned int)m_fillBufferIndex);
        
        pthread_cond_wait(&m_bufferFreeCondition, &m_bufferInUseMutex);
    }
    pthread_mutex_unlock(&m_bufferInUseMutex);
}
    
// this is called by the audio queue when it has finished decoding our data. 
// The buffer is now free to be reused.
void Audio_Queue::audioQueueOutputCallback(void *inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    Audio_Queue *audioQueue = static_cast<Audio_Queue*>(inClientData);
    
    Stream_Configuration *config = Stream_Configuration::configuration();
    
    int bufIndex = -1;
    
    for (unsigned int i = 0; i < config->bufferCount; ++i) {
        if (inBuffer == audioQueue->m_audioQueueBuffer[i]) {
            AQ_TRACE("findQueueBuffer %i\n", i);
            bufIndex = i;
            break;
        }
    }
    
    if (bufIndex == -1) {
        return;
    }
    
    pthread_mutex_lock(&audioQueue->m_bufferInUseMutex);
    
    AQ_ASSERT(audioQueue->m_bufferInUse[bufIndex]);
    
    audioQueue->m_bufferInUse[bufIndex] = false;
    audioQueue->m_buffersUsed--;
    
    AQ_TRACE("signaling buffer free for inuse %i....\n", bufIndex);
    pthread_cond_signal(&audioQueue->m_bufferFreeCondition);
    AQ_TRACE("signal sent!\n");
    
    if (audioQueue->m_buffersUsed == 0 && audioQueue->m_delegate) {
        AQ_LOCK_TRACE("audioQueueOutputCallback: unlock 2\n");
        pthread_mutex_unlock(&audioQueue->m_bufferInUseMutex);
        
        if (audioQueue->m_delegate) {
            audioQueue->m_delegate->audioQueueBuffersEmpty();
        }
    } else {
        pthread_mutex_unlock(&audioQueue->m_bufferInUseMutex);
        
        if (audioQueue->m_delegate) {
            audioQueue->m_delegate->audioQueueFinishedPlayingPacket();
        }
    }
    
    AQ_LOCK_TRACE("audioQueueOutputCallback: unlock\n");
}

void Audio_Queue::audioQueueIsRunningCallback(void *inClientData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
    Audio_Queue *audioQueue = static_cast<Audio_Queue*>(inClientData);
    
    AQ_TRACE("%s: enter\n", __PRETTY_FUNCTION__);
    
    UInt32 running;
    UInt32 output = sizeof(running);
    OSStatus err = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &running, &output);
    if (err) {
        AQ_TRACE("%s: error in kAudioQueueProperty_IsRunning\n", __PRETTY_FUNCTION__);
        return;
    }
    if (running) {
        AQ_TRACE("audio queue running!\n");
        audioQueue->setState(RUNNING);
    } else {
        audioQueue->setState(IDLE);
    }
}    
    
} // namespace astreamer
