#include "CMVideoSampling.h"

#include "CVTextureCache.h"
#include "GlesHelper.h"

#include <OpenGLES/ES3/glext.h>
#include <AVFoundation/AVFoundation.h>

void CMVideoSampling_Initialize(CMVideoSampling* sampling)
{
    ::memset(sampling, 0x00, sizeof(CMVideoSampling));
    sampling->cvTextureCache = CreateCVTextureCache();
}

void CMVideoSampling_Uninitialize(CMVideoSampling* sampling)
{
    if (sampling->cvImageBuffer)
    {
        CFRelease(sampling->cvImageBuffer);
        sampling->cvImageBuffer = 0;
    }
    if (sampling->cvTextureCacheTexture)
    {
        CFRelease(sampling->cvTextureCacheTexture);
        sampling->cvTextureCacheTexture = 0;
    }
    if (sampling->cvTextureCache)
    {
        CFRelease(sampling->cvTextureCache);
        sampling->cvTextureCache = 0;
    }
}

intptr_t CMVideoSampling_SampleBuffer(CMVideoSampling* sampling, void* buffer, size_t* w, size_t* h)
{
    intptr_t retTex = 0;

    if (sampling->cvImageBuffer)
        CFRelease(sampling->cvImageBuffer);
    sampling->cvImageBuffer = CMSampleBufferGetImageBuffer((CMSampleBufferRef)buffer);
    CFRetain(sampling->cvImageBuffer);

    *w = CVPixelBufferGetWidth((CVImageBufferRef)sampling->cvImageBuffer);
    *h = CVPixelBufferGetHeight((CVImageBufferRef)sampling->cvImageBuffer);
    if (sampling->cvTextureCacheTexture)
    {
        CFRelease(sampling->cvTextureCacheTexture);
        FlushCVTextureCache(sampling->cvTextureCache);
    }
    sampling->cvTextureCacheTexture = CreateTextureFromCVTextureCache(sampling->cvTextureCache, sampling->cvImageBuffer, *w, *h);
    if (sampling->cvTextureCacheTexture)
        retTex = GetTextureFromCVTextureCache(sampling->cvTextureCacheTexture);

    if (UnitySelectedRenderingAPI() == apiOpenGLES2 || UnitySelectedRenderingAPI() == apiOpenGLES3)
    {
        GLint oldTexBinding = 0;

        glGetIntegerv(GL_TEXTURE_BINDING_2D, &oldTexBinding);
        glBindTexture(GL_TEXTURE_2D, (GLuint)retTex);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glBindTexture(GL_TEXTURE_2D, oldTexBinding);
    }

    return retTex;
}

intptr_t CMVideoSampling_LastSampledTexture(CMVideoSampling* sampling)
{
    return GetTextureFromCVTextureCache(sampling->cvTextureCacheTexture);
}
