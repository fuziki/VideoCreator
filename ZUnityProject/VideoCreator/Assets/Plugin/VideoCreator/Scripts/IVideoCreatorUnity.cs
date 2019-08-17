using UnityEngine;

namespace VideoCreator {
    public interface IVideoCreatorUnity
    {
        bool IsRecording
        {
            get;
        }
        void StartRecording();
        void Append(Texture texture);
        void FinishRecording();
    }
}
