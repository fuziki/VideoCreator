using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using VideoCreator;

public class H264StreamerTest : MonoBehaviour
{
    public RenderTexture texture = null;

    private float startTime = 0;

    // Start is called before the first frame update
    void Start()
    {
        H264Streamer.Start("ws://localhost:8080", 640, 480);
        startTime = Time.time;
    }

    int cnt = 0;

    bool flag = false;

    // Update is called once per frame
    void Update()
    {
        if(cnt < 180)
        {
            cnt += 1;
            return;
        }
        flag = !flag;
        //if (flag) return;
        Debug.Log("enque");
        long time = (long)((Time.time - startTime) * 1_000_000);
        H264Streamer.Enqueue(texture, time);
    }

    void OnDestroy()
    {
        H264Streamer.Close();
    }
}
