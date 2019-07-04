/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#include "stream_configuration.h"

namespace astreamer {
    
Stream_Configuration::Stream_Configuration() :
    userAgent(NULL),
    cacheDirectory(NULL),
    predefinedHttpHeaderValues(NULL)
{
}

Stream_Configuration::~Stream_Configuration()
{
    if (userAgent) {
        CFRelease(userAgent), userAgent = NULL;
    }
}

Stream_Configuration* Stream_Configuration::configuration()
{
    static Stream_Configuration config;
    return &config;
}
    
}