using UnityEngine;

namespace VideoCreator
{
    public class VideoCreatorUnity : IVideoCreatorUnity
    {
        private IVideoCreatorUnity videoCreator = null;
        public VideoCreatorUnity(string tmpFilePath, bool enableAudio, int videoWidth, int videoHeight)
        {
#if UNITY_EDITOR
            videoCreator = null;
#elif UNITY_IOS
        videoCreator = VideoCreatorUnityIOS(tmpFilePath, enableAudio, videoWidth, videoHeight);
#endif
        }
        public bool IsRecording
        {
            get
            {
                if (videoCreator == null) return false;
                return videoCreator.IsRecording;
            }
        }
        public void StartRecording()
        {
            if (videoCreator == null) return;
            videoCreator.StartRecording();
        }
        public void Append(Texture texture)
        {
            if (videoCreator == null) return;
            videoCreator.Append(texture);
        }
        public void FinishRecording()
        {
            if (videoCreator == null) return;
            videoCreator.FinishRecording();
        }
    }
}
