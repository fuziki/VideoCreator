using UnityEngine;
using UnityEngine.SceneManagement;
using VideoCreator;

public class HlsSample : MonoBehaviour
{
    [SerializeField]
    private RenderTexture texture;

    [SerializeField]
    private HlsServer hlsServer;

    private readonly long startTimeOffset = 6_000_000;

    private bool isRecording = false;

    private string cachePath = "";
    private float startTime = 0;

    // Start is called before the first frame update
    void Start()
    {
        Application.targetFrameRate = 30;
        SceneManager.LoadScene("Common", LoadSceneMode.Additive);

        cachePath = "file://" + Application.temporaryCachePath + "/tmp.mov";
        Debug.Log($"cachePath: {cachePath}, {texture.width}x{texture.height}");

        Debug.Log("access http://XXX.XXX.XXX.XXX:8080/index");
    }

    // Update is called once per frame
    void Update()
    {
        if (!isRecording || !MediaCreator.IsRecording()) return;

        long time = (long)((Time.time - startTime) * 1_000_000) + startTimeOffset;

        Debug.Log($"write texture: {time}");

        MediaCreator.WriteVideo(texture, time);
    }

    void OnDestroy()
    {
        StopHls();
    }

    public void StartHls()
    {
        if (isRecording) return;

        MediaCreator.SetOnSegmentDataAction((data) =>
        {
            Debug.Log($"on segment: {data.Length}");
            hlsServer.OnSegmentData(data);
        });

        MediaCreator.InitAsHlsWithNoAudio(cachePath, "h264", texture.width, texture.height, 1_000_000);
        MediaCreator.Start(startTimeOffset);

        startTime = Time.time;

        isRecording = true;
    }

    public void StopHls()
    {
        if (!isRecording) return;

        MediaCreator.FinishSync();

        isRecording = false;
    }
}
