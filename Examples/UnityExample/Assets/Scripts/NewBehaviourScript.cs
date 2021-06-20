using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using VideoCreator;

public class NewBehaviourScript : MonoBehaviour {

    public RenderTexture texture = null;

    public Text text;

    private bool isRecording = false;

    private string cachePath = "";

    private long amountFrame = 0;

    // Use this for initialization
    void Start () {
        cachePath = "file://" + Application.temporaryCachePath + "/tmp.wav";

        Debug.Log($"cachePath: {cachePath}");

        var source = gameObject.AddComponent<AudioSource>();
        var clip = Microphone.Start(null, true, 1, 48000);
        source.clip = clip;
        source.loop = true;
        while (Microphone.GetPosition(null) < 0) { }

        source.Play();
    }
	
	// Update is called once per frame
	void Update () {

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

        //MediaCreator.writeVideo(texture, 0);
    }

    public void StartRecord()
    {
        if (isRecording) return;

        MediaCreator.initAsWav(cachePath, 1, 48000, 32);
        MediaCreator.start(0);

        isRecording = true;

        text.text = "start recording !!";
    }

    public void FinishRecord()
    {
        if (!isRecording) return;
        MediaCreator.finishSync();
        isRecording = false;

        text.text = "finish recording !!";


    }

    void OnAudioFilterRead(float[] data, int channels)
    {

        if (!isRecording) return;
        if (!MediaCreator.isRecording()) return;

        MediaCreator.writeAudio(data, amountFrame * 1_000_000 / 48_000);

        amountFrame += data.Length;

        for (int i = 0; i < data.Length; i++)
        {
            data[i] = 0;
        }
    }

    private float vy = 0.0f;
    public void Jump()
    {
        vy += 0.1f;
        this.transform.position += new Vector3(0, vy, 0);
    }

}
