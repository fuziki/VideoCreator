using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class OldNewBehaviourScript : MonoBehaviour
{

    private VideoCreator.VideoCreatorUnity videoCreatorUnity;

    public RenderTexture texture = null;

    public Text text;

    private bool isRecording = false;

    // Use this for initialization
    void Start()
    {
        videoCreatorUnity = new VideoCreator.VideoCreatorUnity(Application.temporaryCachePath + "/tmp.mov", true, 1920, 1080);
    }

    // Update is called once per frame
    void Update()
    {

        if (this.transform.position.y < 0)
        {
            vy = 0.0f;
            this.transform.position = new Vector3(0, 0, 0);
        }
        else
        {
            vy -= 0.006f;
            this.transform.position += new Vector3(0, vy, 0);
        }


        this.transform.Rotate(2, -3, 4);

        if (!isRecording) return;

        if (texture == null) return;

        videoCreatorUnity.Append(texture);

    }

    public void StartRecord()
    {
        if (isRecording) return;
        videoCreatorUnity.StartRecording();
        isRecording = true;

        text.text = "start recording !!";
    }

    public void FinishRecord()
    {
        if (!isRecording) return;
        videoCreatorUnity.FinishRecording();
        isRecording = false;

        text.text = "finish recording !!";
    }

    private float vy = 0.0f;
    public void Jump()
    {
        vy += 0.1f;
        this.transform.position += new Vector3(0, vy, 0);
    }

}
