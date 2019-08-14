using System;
using System.Runtime.InteropServices;
using UnityEngine;

public class VideoCreatorUnity {

    [DllImport("__Internal")]
    private static extern IntPtr videoCreator_init(string tmpFilePath, bool enableAudio, int videoWidth, int videoHeight);

    [DllImport("__Internal")]
    private static extern bool videoCreator_isRecording(IntPtr creator);

    [DllImport("__Internal")]
    private static extern void videoCreator_startRecording(IntPtr creator);

    [DllImport("__Internal")]
    private static extern void videoCreator_append(IntPtr creator, IntPtr mtlTexture);

    [DllImport("__Internal")]
    private static extern void videoCreator_finishRecording(IntPtr creator);

    private IntPtr creatorObject;
    public VideoCreatorUnity(string tmpFilePath, bool enableAudio, int videoWidth, int videoHeight)
    {
        creatorObject = videoCreator_init(tmpFilePath, enableAudio, videoWidth, videoHeight);
    }

    public bool isRecording
    {
        get
        {
            return videoCreator_isRecording(creatorObject);
        }
    }

    public void startRecording()
    {
        videoCreator_startRecording(creatorObject);
    }

    public void append(Texture texture)
    {
        videoCreator_append(creatorObject, texture.GetNativeTexturePtr());
    }

    public void finishRecording()
    {
        videoCreator_finishRecording(creatorObject);
    }
}
