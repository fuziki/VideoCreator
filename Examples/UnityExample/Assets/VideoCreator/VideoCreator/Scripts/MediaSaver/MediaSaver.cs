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
#endif

        public static void SaveVideo(string url)
        {
#if UNITY_IOS
            UnityMediaSaver_saveVideo(url);
#endif
        }

        public static void SaveLivePhotos(Texture texture, string contentIdentifier, string url)
        {
#if UNITY_IOS
            UnityMediaSaver_saveLivePhotos(texture.GetNativeTexturePtr(), contentIdentifier, url);
#endif
        }

        public static void SaveImage(Texture texture, string type)
        {
#if UNITY_IOS
            UnityMediaSaver_saveImage(texture.GetNativeTexturePtr(), type);
#endif
        }
    }
}
