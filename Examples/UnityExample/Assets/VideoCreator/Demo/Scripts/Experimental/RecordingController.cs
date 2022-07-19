using UnityEngine;
using UnityEngine.UI;
using VideoCreator;

[RequireComponent(typeof(AudioSource))]
public class RecordingController : MonoBehaviour
{
    public RenderTexture texture = null;

    public Text text;

    public HlsServer hlsServer;

    private bool isRecording = false;
    private bool recordTexture = false;
    private bool recordAudio = false;
    private bool saveAfterFinish = false;
    private int livePhotosRecording = -1;

    private string uuid = "";
    private string cachePath = "";

    private long amountFrame = 0;
    private float startTime = 0;

    private long startTimeOffset = 6_000_000;


    // Start is called before the first frame update
    void Start()
    {
        Application.targetFrameRate = 30;

        var source = gameObject.AddComponent<AudioSource>();
        source.Stop();
    }

    // Update is called once per frame
    void Update()
    {
        if (!recordTexture) return;
        if (!MediaCreator.IsRecording()) return;

        long time = (long)((Time.time - startTime) * 1_000_000) + startTimeOffset;

        Debug.Log($"write texture: {time}");

        MediaCreator.WriteVideo(texture, time);

        if (livePhotosRecording < 0) return;
        livePhotosRecording += 1;
        if (livePhotosRecording > 60) FinishRec();
    }

    public void TakeFrame()
    {
        MediaSaver.SaveImage(texture, "png");
    }

    public void RecLivePhotos()
    {
        if (isRecording) return;
        text.text = "start rec live photo!";

        cachePath = "file://" + Application.temporaryCachePath + "/tmp.mov";
        Debug.Log($"cachePath: {cachePath}, {texture.width}x{texture.height}");

        uuid = System.Guid.NewGuid().ToString();
        MediaCreator.InitAsMovWithNoAudio(cachePath, "h264", texture.width, texture.height, uuid);
        MediaCreator.Start(startTimeOffset);

        startTime = Time.time;

        isRecording = true;
        recordTexture = true;
        recordAudio = false;
        saveAfterFinish = false;
        amountFrame = 0;
        livePhotosRecording = 1;
    }

    public void StartRecMovWithAudio()
    {
        if (isRecording) return;
        text.text = "start rec mov with audio!";

        var source = gameObject.AddComponent<AudioSource>();
        var clip = Microphone.Start(null, true, 1, 48_000);
        source.clip = clip;
        source.loop = true;
        while (Microphone.GetPosition(null) < 0) { }

        cachePath = "file://" + Application.temporaryCachePath + "/tmp.mov";
        Debug.Log($"cachePath: {cachePath}, {texture.width}x{texture.height}");

        MediaCreator.InitAsMovWithAudio(cachePath, "h264", texture.width, texture.height, 1, 48_000);
        MediaCreator.Start(startTimeOffset);

        startTime = Time.time;

        uuid = "";
        isRecording = true;
        recordTexture = true;
        recordAudio = true;
        saveAfterFinish = true;
        amountFrame = 0;
        livePhotosRecording = -1;

        source.Play();
    }

    public void StartRecMovWithNoAudio()
    {
        if (isRecording) return;
        text.text = "start rec mov with no audio!";

        cachePath = "file://" + Application.temporaryCachePath + "/tmp.mov";
        Debug.Log($"cachePath: {cachePath}, {texture.width}x{texture.height}");

        MediaCreator.InitAsMovWithNoAudio(cachePath, "h264", texture.width, texture.height);
        MediaCreator.Start(startTimeOffset);

        startTime = Time.time;

        uuid = "";
        isRecording = true;
        recordTexture = true;
        recordAudio = false;
        saveAfterFinish = true;
        amountFrame = 0;
        livePhotosRecording = -1;
    }

    public void StartRecWav()
    {
        if (isRecording) return;
        text.text = "start rec wav!";

        var source = gameObject.AddComponent<AudioSource>();
        var clip = Microphone.Start(null, true, 1, 48_000);
        source.clip = clip;
        source.loop = true;
        while (Microphone.GetPosition(null) < 0) { }

        cachePath = "file://" + Application.temporaryCachePath + "/tmp.wav";
        Debug.Log($"cachePath: {cachePath}");

        MediaCreator.InitAsWav(cachePath, 1, 48000, 32);
        MediaCreator.Start(startTimeOffset);

        startTime = Time.time;

        uuid = "";
        isRecording = true;
        recordTexture = false;
        recordAudio = true;
        saveAfterFinish = false;
        amountFrame = 0;
        livePhotosRecording = -1;

        source.Play();
    }

    public void StartHls()
    {
        if (isRecording) return;
        text.text = "start hls!";

        cachePath = "file://" + Application.temporaryCachePath + "/tmp.mov";
        Debug.Log($"cachePath: {cachePath}, {texture.width}x{texture.height}");

        MediaCreator.SetOnSegmentDataAction((data) =>
        {
            Debug.Log($"on segment: {data.Length}");
            hlsServer.OnSegmentData(data);
        });

        MediaCreator.InitAsHlsWithNoAudio(cachePath, "h264", texture.width, texture.height, 1_000_000);
        MediaCreator.Start(startTimeOffset);

        startTime = Time.time;

        uuid = "";
        isRecording = true;
        recordTexture = true;
        recordAudio = false;
        saveAfterFinish = false;
        amountFrame = 0;
        livePhotosRecording = -1;
    }

    public void FinishRec()
    {
        if (!isRecording) return;
        text.text = "finish recording";

        var source = gameObject.AddComponent<AudioSource>();
        source.Stop();

        MediaCreator.FinishSync();
        if (saveAfterFinish)
        {
            MediaSaver.SaveVideo(cachePath);
        }

        if (livePhotosRecording > 0)
        {
            MediaSaver.SaveLivePhotos(texture, uuid, cachePath);
        }

        isRecording = false;
        recordTexture = false;
        recordAudio = false;
        saveAfterFinish = false;
        livePhotosRecording = -1;
    }

    void OnAudioFilterRead(float[] data, int channels)
    {
        writeAudio(data, channels);

        for (int i = 0; i < data.Length; i++)
        {
            data[i] = 0;
        }
    }

    private void writeAudio(float[] data, int channels)
    {
        if (!recordAudio) return;
        if (!MediaCreator.IsRecording()) return;


        long time = (amountFrame * 1_000_000 / 48_000) + startTimeOffset;
        Debug.Log($"write audio: {time}");

        MediaCreator.WriteAudio(data, time);

        amountFrame += data.Length;
    }
}

