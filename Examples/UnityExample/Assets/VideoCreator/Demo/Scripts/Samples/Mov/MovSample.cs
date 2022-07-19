using UnityEngine;
using UnityEngine.SceneManagement;
using VideoCreator;

[RequireComponent(typeof(AudioSource))]
public class MovSample : MonoBehaviour
{
    [SerializeField]
    private RenderTexture texture;

    [SerializeField]
    private AudioSource audioSource;

    private readonly long startTimeOffset = 6_000_000;

    private bool isRecording = false;
    private bool recordAudio = false;

    private string cachePath = "";
    private float startTime = 0;
    private long amountAudioFrame = 0;

    // Start is called before the first frame update
    void Start()
    {
        Application.targetFrameRate = 30;
        SceneManager.LoadScene("Common", LoadSceneMode.Additive);

        audioSource.Stop();

        cachePath = "file://" + Application.temporaryCachePath + "/tmp.mov";
        Debug.Log($"cachePath: {cachePath}, {texture.width}x{texture.height}");
    }

    // Update is called once per frame
    void Update()
    {
        if (!isRecording || !MediaCreator.IsRecording()) return;

        long time = (long)((Time.time - startTime) * 1_000_000) + startTimeOffset;

        Debug.Log($"write texture: {time}");

        MediaCreator.WriteVideo(texture, time);
    }

    void OnAudioFilterRead(float[] data, int channels)
    {
        WriteAudio(data, channels);

        for (int i = 0; i < data.Length; i++)
        {
            data[i] = 0;
        }
    }

    private void WriteAudio(float[] data, int channels)
    {
        if (!isRecording || !recordAudio || !MediaCreator.IsRecording()) return;

        long time = (amountAudioFrame * 1_000_000 / 48_000) + startTimeOffset;
        Debug.Log($"write audio: {time}");

        MediaCreator.WriteAudio(data, time);

        amountAudioFrame += data.Length;
    }

    void OnDestroy()
    {
        StopRec();
    }

    public void StartRecMovWithAudio()
    {
        if (isRecording) return;

        var clip = Microphone.Start(null, true, 1, 48_000);
        audioSource.clip = clip;
        audioSource.loop = true;
        while (Microphone.GetPosition(null) < 0) { }

        MediaCreator.InitAsMovWithAudio(cachePath, "h264", texture.width, texture.height, 1, 48_000);
        MediaCreator.Start(startTimeOffset);

        startTime = Time.time;

        isRecording = true;
        recordAudio = true;
        amountAudioFrame = 0;

        audioSource.Play();
    }

    public void StartRecMovWithNoAudio()
    {
        if (isRecording) return;

        MediaCreator.InitAsMovWithNoAudio(cachePath, "h264", texture.width, texture.height);
        MediaCreator.Start(startTimeOffset);

        startTime = Time.time;

        isRecording = true;
        recordAudio = false;
    }

    public void StopRec()
    {
        if (!isRecording) return;

        audioSource.Stop();
        Microphone.End(null);

        MediaCreator.FinishSync();
        MediaSaver.SaveVideo(cachePath);

        isRecording = false;
    }
}
