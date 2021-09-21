using AOT;
using UnityEngine;
using System;
using System.Runtime.InteropServices;

namespace VideoCreator
{
    public class MediaCreator
    {
#if !UNITY_EDITOR && UNITY_IOS
        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_initAsMovWithNoAudio(string url, string codec, long width, long height, string contentIdentifier);

        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_initAsMovWithAudio(string url, string codec, long width, long height, long channel, float samplingRate, string contentIdentifier);

        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_initAsWav(string url, long channel, float samplingRate, long bitDepth);

        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_initAsHlsWithNoAudio(string url, string codec, long width, long height, long segmentDurationMicroSec);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate void UnityMediaCreator_setOnSegmentData_delegate(IntPtr data, long len);

        [DllImport("__Internal")]
        private static extern void UnityMediaCreator_setOnSegmentData(UnityMediaCreator_setOnSegmentData_delegate handler);

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

        /// <summary>
        /// Setup MediaCreator for mov file with no audio
        /// </summary>
        /// <param name="url">Video file url</param>
        /// <param name="codec">"h264" or "hevcWithAlpha". If you want to record a video with an alpha channel, you need to specify the "hevcWithAlpha".</param>
        /// <param name="width">Video width</param>
        /// <param name="height">Video height</param>
        /// <param name="contentIdentifier">Only if you want LivePhotos, please set this. You will need to set the same id when you save the file.</param>
        public static void InitAsMovWithNoAudio(string url, string codec, long width, long height, string contentIdentifier = "")
        {
#if !UNITY_EDITOR && UNITY_IOS
            UnityMediaCreator_initAsMovWithNoAudio(url, codec, width, height, contentIdentifier);
#else
            Debug.Log("This platform is not supported.");
#endif
        }

        /// <summary>
        /// Setup MediaCreator for mov file with audio
        /// </summary>
        /// <param name="url">Video file url</param>
        /// <param name="codec">"h264" or "hevcWithAlpha". If you want to record a video with an alpha channel, you need to specify the "hevcWithAlpha".</param>
        /// <param name="width">Video width</param>
        /// <param name="height">Video height</param>
        /// <param name="channel">Audio source channel</param>
        /// <param name="samplingRate">Audio source sample rate</param>
        /// <param name="contentIdentifier">Only if you want LivePhotos, please set this. You will need to set the same id when you save the file.</param>
        public static void InitAsMovWithAudio(string url, string codec, long width, long height, long channel, float samplingRate, string contentIdentifier = "")
        {
#if !UNITY_EDITOR && UNITY_IOS
            UnityMediaCreator_initAsMovWithAudio(url, codec, width, height, channel, samplingRate, contentIdentifier);
#else
            Debug.Log("This platform is not supported.");
#endif
        }

        /// <summary>
        /// Setup MediaCreator for wav file
        /// </summary>
        /// <param name="url">wav file url</param>
        /// <param name="channel">Audio source channel</param>
        /// <param name="samplingRate">Audio source sample rate</param>
        /// <param name="bitDepth">wav file bitDepth</param>
        public static void InitAsWav(string url, long channel, float samplingRate, long bitDepth)
        {
#if !UNITY_EDITOR && UNITY_IOS
            UnityMediaCreator_initAsWav(url, channel, samplingRate, bitDepth);
#else
            Debug.Log("This platform is not supported.");
#endif
        }

        public static void InitAsHlsWithNoAudio(string url, string codec, long width, long height, long segmentDurationMicroSec)
        {
#if !UNITY_EDITOR && UNITY_IOS
            UnityMediaCreator_initAsHlsWithNoAudio(url, codec, width, height, segmentDurationMicroSec);
#else
            Debug.Log("This platform is not supported.");
#endif
        }

        /// <summary>
        /// Start recoding
        /// </summary>
        /// <param name="microSec">Start time in the timeline of the source samples. Unit is microseconds.</param>
        public static void Start(long microSec)
        {
#if !UNITY_EDITOR && UNITY_IOS
            UnityMediaCreator_start(microSec);
#else
            Debug.Log("This platform is not supported.");
#endif
        }

        private static Action<byte[]> onSegmentDataAction;

#if !UNITY_EDITOR && UNITY_IOS
        [MonoPInvokeCallback(typeof(UnityMediaCreator_setOnSegmentData_delegate))]
        private static void OnSegmentDataCallback(IntPtr data, long len)
        {
            byte[] result = new byte[len];
            Marshal.Copy(data, result, 0, (int)len);
            onSegmentDataAction(result);
        }
#else
        private static void OnSegmentDataCallback(IntPtr data, long len)
        {
            byte[] result = new byte[len];
            Marshal.Copy(data, result, 0, (int)len);
            onSegmentDataAction(result);
        }
#endif
        /// <summary>
        /// Set Flagmented MP4 Handler for HLS
        /// </summary>
        public static void SetOnSegmentDataAction(Action<byte[]> action)
        {
            onSegmentDataAction = action;
#if !UNITY_EDITOR && UNITY_IOS
            UnityMediaCreator_setOnSegmentData(OnSegmentDataCallback);
#else
            Debug.Log("This platform is not supported.");
#endif
        }

        /// <summary>
        /// Finish recoding
        /// </summary>
        public static void FinishSync()
        {
#if !UNITY_EDITOR && UNITY_IOS
            UnityMediaCreator_finishSync();
#else
            Debug.Log("This platform is not supported.");
#endif
        }

        /// <summary>
        /// Check if recording
        /// </summary>
        public static bool IsRecording()
        {
#if !UNITY_EDITOR && UNITY_IOS
            return UnityMediaCreator_isRecording();
#else
            return false;
#endif
        }

        /// <summary>
        /// Write texture
        /// </summary>
        /// <param name="texture">Write target texture</param>
        /// <param name="microSec">Time based on start time</param>
        public static void WriteVideo(Texture texture, long microSec)
        {
#if !UNITY_EDITOR && UNITY_IOS
            UnityMediaCreator_writeVideo(texture.GetNativeTexturePtr(), microSec);
#else
            Debug.Log("This platform is not supported.");
#endif
        }

        /// <summary>
        /// Write audio
        /// </summary>
        /// <param name="pcm">Audio source pcm</param>
        /// <param name="microSec">Time based on start time</param>
        public static void WriteAudio(float[] pcm, long microSec)
        {
#if !UNITY_EDITOR && UNITY_IOS
            UnityMediaCreator_writeAudio(pcm, pcm.Length, microSec);
#else
            Debug.Log("This platform is not supported.");
#endif
        }

    }
}
