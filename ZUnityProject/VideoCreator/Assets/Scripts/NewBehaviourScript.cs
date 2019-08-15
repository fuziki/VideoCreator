using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NewBehaviourScript : MonoBehaviour {

    private VideoCreatorUnity videoCreatorUnity;

    public RenderTexture texture = null;

    private bool isRecording = false;

    // Use this for initialization
    void Start () {
        videoCreatorUnity = new VideoCreatorUnity(Application.temporaryCachePath + "/tmp.mov", true, 1920, 1080);
	}
	
	// Update is called once per frame
	void Update () {

        this.transform.Rotate(2, -3, 4);

        if (!isRecording) return;

        if (texture == null) return;

        videoCreatorUnity.append(texture);

	}

    public void StartRecord()
    {
        if (isRecording) return;
        videoCreatorUnity.startRecording();
        isRecording = true;
    }

    public void FinishRecord()
    {
        if (!isRecording) return;
        videoCreatorUnity.finishRecording();
        isRecording = false;
    }
}
