using UnityEngine;
using System;
using System.Runtime.InteropServices;

namespace VideoCreator
{
    public class H264Streamer
    {
#if UNITY_EDITOR_OSX
        [DllImport("mcUnityVideoCreator")]
        private static extern void H264Streamer_Start(string url, long width, long height);

        [DllImport("mcUnityVideoCreator")]
        private static extern void H264Streamer_Enqueue(IntPtr texturePtr, long microSec);

        [DllImport("mcUnityVideoCreator")]
        private static extern void H264Streamer_Close();
#endif

        public static void Start(string url, long width, long height)
        {
#if UNITY_EDITOR_OSX
            H264Streamer_Start(url, width, height);
#else
            Debug.Log("This platform is not supported.");
#endif
        }

        public static void Enqueue(Texture texture, long microSec)
        {
#if UNITY_EDITOR_OSX
            H264Streamer_Enqueue(texture.GetNativeTexturePtr(), microSec);
#else
            Debug.Log("This platform is not supported.");
#endif
        }

        public static void Close()
        {
#if UNITY_EDITOR_OSX
            H264Streamer_Close();
#else
            Debug.Log("This platform is not supported.");
#endif
        }
    }
}