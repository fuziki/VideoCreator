using UnityEngine;
using System;
using System.Runtime.InteropServices;

namespace VideoCreator
{
    public class MediaSaver
    {
#if !UNITY_EDITOR && UNITY_IOS
        [DllImport("__Internal")]
        private static extern void UnityMediaSaver_saveVideo(string url);

        [DllImport("__Internal")]
        private static extern void UnityMediaSaver_saveLivePhotos(IntPtr texturePtr, string contentIdentifier, string url);

        [DllImport("__Internal")]
        private static extern void UnityMediaSaver_saveImage(IntPtr texturePtr, string type);
#endif

        /// <summary>
        /// Save video to album from url
        /// </summary>
        /// <param name="url">Video file url</param>
        public static void SaveVideo(string url)
        {
#if !UNITY_EDITOR && UNITY_IOS
            UnityMediaSaver_saveVideo(url);
#else
            Debug.Log("This platform is not supported.");
#endif
        }

        /// <summary>
        /// Save Live Photos to album
        /// </summary>
        /// <param name="texture">Still image</param>
        /// <param name="contentIdentifier">Set the same Content Identifier as the video.</param>
        /// <param name="url">Video file url</param>
        public static void SaveLivePhotos(Texture texture, string contentIdentifier, string url)
        {
#if !UNITY_EDITOR && UNITY_IOS
            UnityMediaSaver_saveLivePhotos(texture.GetNativeTexturePtr(), contentIdentifier, url);
#else
            Debug.Log("This platform is not supported.");
#endif
        }

        /// <summary>
        /// Save Image to album
        /// </summary>
        /// <param name="texture">Target Texture</param>
        /// <param name="type">Image Format. Choose from "jpeg", "jpg", "heif", "png"</param>
        public static void SaveImage(Texture texture, string type)
        {
#if !UNITY_EDITOR && UNITY_IOS
            UnityMediaSaver_saveImage(texture.GetNativeTexturePtr(), type);
#else
            Debug.Log("This platform is not supported.");
#endif
        }
    }
}
