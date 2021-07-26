using UnityEngine;
using System;
using System.Runtime.InteropServices;

namespace VideoCreator
{
    public class MediaSaver
    {
#if UNITY_IOS
        [DllImport("__Internal")]
        private static extern void UnityMediaSaver_saveVideo(string url);

        [DllImport("__Internal")]
        private static extern void UnityMediaSaver_saveLivePhotos(IntPtr texturePtr, string contentIdentifier, string url);

        [DllImport("__Internal")]
        private static extern void UnityMediaSaver_saveImage(IntPtr texturePtr, string type);

        public static void SaveVideo(string url)
        {
            UnityMediaSaver_saveVideo(url);
        }

        public static void SaveLivePhotos(Texture texture, string contentIdentifier, string url)
        {
            UnityMediaSaver_saveLivePhotos(texture.GetNativeTexturePtr(), contentIdentifier, url);
        }

        public static void SaveImage(Texture texture, string type)
        {
            UnityMediaSaver_saveImage(texture.GetNativeTexturePtr(), type);
        }
#endif
    }

    public class MediaCreator
    {
#if UNITY_IOS
        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_initAsMovWithNoAudio(string url, string codec, long width, long height, string contentIdentifier);

        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_initAsMovWithAudio(string url, string codec, long width, long height, long channel, float samplingRate, string contentIdentifier);

        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_initAsWav(string url, long channel, float samplingRate, long bitDepth);

        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_start(long microSec);

        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_finishSync();

        [DllImport("__Internal")]
        private static extern bool UnityMediaCreator_isRecording();

        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_writeVideo(IntPtr texturePtr, long microSec);

        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_writeAudio(float[] pcm, long frame, long microSec);
#endif

        public static void InitAsMovWithNoAudio(string url, string codec, long width, long height, string contentIdentifier = "")
        {
#if UNITY_IOS
            UnityMediaCreator_initAsMovWithNoAudio(url, codec, width, height, contentIdentifier);
#endif
        }

        public static void InitAsMovWithAudio(string url, string codec, long width, long height, long channel, float samplingRate, string contentIdentifier = "")
        {
#if UNITY_IOS
            UnityMediaCreator_initAsMovWithAudio(url, codec, width, height, channel, samplingRate, contentIdentifier);
#endif
        }

        public static void InitAsWav(string url, long channel, float samplingRate, long bitDepth)
        {
#if UNITY_IOS
            UnityMediaCreator_initAsWav(url, channel, samplingRate, bitDepth);
#endif
        }

        public static void Start(long microSec)
        {
#if UNITY_IOS
            UnityMediaCreator_start(microSec);
#endif
        }

        public static void FinishSync()
        {
#if UNITY_IOS
            UnityMediaCreator_finishSync();
#endif
        }

        public static bool IsRecording()
        {
#if UNITY_IOS
            return UnityMediaCreator_isRecording();
#else
        return false;
#endif
        }

        public static void WriteVideo(Texture texture, long microSec)
        {
#if UNITY_IOS
            UnityMediaCreator_writeVideo(texture.GetNativeTexturePtr(), microSec);
#endif
        }

        public static void WriteAudio(float[] pcm, long microSec)
        {
#if UNITY_IOS
            UnityMediaCreator_writeAudio(pcm, pcm.Length, microSec);
#endif
        }

    }
}
