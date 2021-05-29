using System;
using System.Runtime.InteropServices;
using UnityEngine;

#if UNITY_IOS
namespace VideoCreator
{
    public class VideoCreatorUnityIOS : IVideoCreatorUnity
    {

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
        public VideoCreatorUnityIOS(string tmpFilePath, bool enableAudio, int videoWidth, int videoHeight)
        {
            this.width = videoWidth;
            this.height = videoHeight;
            creatorObject = videoCreator_init(tmpFilePath, enableAudio, videoWidth, videoHeight);
        }

        ~VideoCreatorUnityIOS()
        {
            videoCreator_release(creatorObject);
        }

        public bool IsRecording
        {
            get
            {
                return videoCreator_isRecording(creatorObject);
            }
        }

        public void StartRecording()
        {
            videoCreator_startRecording(creatorObject);
        }

        public void Append(Texture texture)
        {
            if (texture.width != this.width || texture.height != this.height) return;
            videoCreator_append(creatorObject, texture.GetNativeTexturePtr());
        }

        public void FinishRecording()
        {
            videoCreator_finishRecording(creatorObject);
        }
    }
}
#endif
