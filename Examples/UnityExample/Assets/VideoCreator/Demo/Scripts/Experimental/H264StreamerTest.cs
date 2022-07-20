using UnityEngine;
using VideoCreator;

public class H264StreamerTest : MonoBehaviour
{
    public RenderTexture texture = null;

    private float startTime = 0;

    // Start is called before the first frame update
    void Start()
    {
        Application.targetFrameRate = 30;
        H264Streamer.Start("ws://localhost:8080", 640, 480);
        startTime = Time.time;
    }

    // Update is called once per frame
    void Update()
    {
        long time = (long)((Time.time - startTime) * 1_000_000);
        Debug.Log($"enqueue texture: {time}");
        H264Streamer.Enqueue(texture, time);
    }

    void OnDestroy()
    {
        H264Streamer.Close();
    }
}
