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

    [DllImport("__Internal")]
    private static extern void videoCreator_release(IntPtr creator);

    private int width;
    private int height;

    private IntPtr creatorObject;
    public VideoCreatorUnity(string tmpFilePath, bool enableAudio, int videoWidth, int videoHeight)
    {
        this.width = videoWidth;
        this.height = videoHeight;
        creatorObject = videoCreator_init(tmpFilePath, enableAudio, videoWidth, videoHeight);
    }

    ~VideoCreatorUnity()
    {
        videoCreator_release(creatorObject);
    }

    public bool isRecording
    {
        get
        {
            return videoCreator_isRecording(creatorObject);
        }
    }

    private Texture2D texture2D = null;

    public void startRecording()
    {
        videoCreator_startRecording(creatorObject);
    }

    public void append(Texture2D texture)
    {
        videoCreator_append(creatorObject, texture.GetNativeTexturePtr());
    }

    public void append(RenderTexture texture)
    {
        if (texture.width != this.width || texture.height != this.height) return;
        videoCreator_append(creatorObject, texture.GetNativeTexturePtr());
        return;
        if (texture2D == null) texture2D = new Texture2D((int)texture.width, (int)texture.height, TextureFormat.ARGB32, false);
        RenderTexture currentRT = RenderTexture.active;
        RenderTexture.active = texture;
        //Now Abailable to send only 480 x 640
        if (texture2D.width != texture.width || texture2D.height != texture.height)
        {
            texture2D = new Texture2D((int)texture.width, (int)texture.height, TextureFormat.ARGB32, false);
        }
        texture2D.ReadPixels(new Rect(0, 0, texture.width, texture.height), 0, 0);
        texture2D.Apply();
        RenderTexture.active = currentRT;
        this.append(texture2D);
    }


    public void finishRecording()
    {
        videoCreator_finishRecording(creatorObject);
    }
}
