//
//  VideoCreatorUnity.mm
//  UnityUser
//
//  Created by fuziki on 2019/08/14.
//  Copyright © 2019 fuziki.factory. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/MTLTexture.h>
#import <Metal/Metal.h>
#import <VideoCreator/VideoCreator-Swift.h>

extern "C" {
    VideoCreatorUnity* videoCreator_init(char* tmpFilePath, bool enableAudio, int videoWidth, int videoHeight);
    bool videoCreator_isRecording(VideoCreatorUnity* creator);
    void videoCreator_startRecording(VideoCreatorUnity* creator);
    void videoCreator_append(VideoCreatorUnity* creator, unsigned char* mtlTexture);
    void videoCreator_finishRecording(VideoCreatorUnity* creator);
    void videoCreator_release(VideoCreatorUnity* creator);
}

VideoCreatorUnity* videoCreator_init(char* tmpFilePath, bool enableAudio, int videoWidth, int videoHeight) {
    VideoCreatorUnity* creator =
    [[VideoCreatorUnity alloc] initWithTmpFilePath: [NSString stringWithUTF8String: tmpFilePath]
                                         enableMic: enableAudio
                                        videoWidth: videoWidth
                                       videoHeight: videoHeight];
    CFRetain((CFTypeRef)creator);
    return creator;
}

bool videoCreator_isRecording(VideoCreatorUnity* creator) {
    return [creator isRecording];
}

void videoCreator_startRecording(VideoCreatorUnity* creator) {
    [creator startRecording];
}

void videoCreator_append(VideoCreatorUnity* creator, unsigned char* mtlTexture) {
    id<MTLTexture> tex = (__bridge id<MTLTexture>) (void*) mtlTexture;
    if (tex.pixelFormat != MTLPixelFormatBGRA8Unorm_sRGB) {
        tex = [tex newTextureViewWithPixelFormat: MTLPixelFormatBGRA8Unorm_sRGB];
    }
    [creator appendWithMtlTexture: tex];
}

void videoCreator_finishRecording(VideoCreatorUnity* creator) {
    [creator finishRecording];
}

void videoCreator_release(VideoCreatorUnity* creator) {
    CFRelease((CFTypeRef)creator);
}
