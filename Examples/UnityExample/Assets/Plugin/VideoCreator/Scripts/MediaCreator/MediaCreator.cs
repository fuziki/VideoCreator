//using System.Collections;
//using System.Collections.Generic;
using UnityEngine;
using System;
using System.Runtime.InteropServices;

namespace VideoCreator
{
    public class MediaCreator
    {
#if UNITY_IOS
        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_initAsMovWithNoAudio(string url, string codec, long width, long height);

        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_initAsMovWithAudio(string url, string codec, long width, long height, long channel, float samplingRate);

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

        public static void initAsMovWithNoAudio(string url, string codec, long width, long height)
        {
#if UNITY_IOS
            UnityMediaCreator_initAsMovWithNoAudio(url, codec, width, height);
#endif
        }

        public static void initAsMovWithAudio(string url, string codec, long width, long height, long channel, float samplingRate)
        {
#if UNITY_IOS
            UnityMediaCreator_initAsMovWithAudio(url, codec, width, height, channel, samplingRate);
#endif
        }

        public static void initAsWav(string url, long channel, float samplingRate, long bitDepth)
        {
#if UNITY_IOS
            UnityMediaCreator_initAsWav(url, channel, samplingRate, bitDepth);
#endif
        }

        public static void start(long microSec)
        {
#if UNITY_IOS
            UnityMediaCreator_start(microSec);
#endif
        }

        public static void finishSync()
        {
#if UNITY_IOS
            UnityMediaCreator_finishSync();
#endif
        }

        public static bool isRecording()
        {
#if UNITY_IOS
            return UnityMediaCreator_isRecording();
#else
        return false;
#endif
        }

        public static void writeVideo(Texture texture, long microSec)
        {
#if UNITY_IOS
            UnityMediaCreator_writeVideo(texture.GetNativeTexturePtr(), microSec);
#endif
        }

        public static void writeAudio(float[] pcm, long microSec)
        {
#if UNITY_IOS
            UnityMediaCreator_writeAudio(pcm, pcm.Length, microSec);
#endif
        }

    }
}