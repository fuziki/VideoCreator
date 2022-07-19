using UnityEngine;
using UnityEngine.SceneManagement;
using VideoCreator;

public class LivePhotsSample : MonoBehaviour
{
    [SerializeField]
    private RenderTexture texture;

    private readonly long startTimeOffset = 6_000_000;

    private bool isRecording = false;

    private string cachePath = "";
    private string uuid = "";
    private float startTime = 0;

    // Start is called before the first frame update
    void Start()
    {
        Application.targetFrameRate = 30;
        SceneManager.LoadScene("Common", LoadSceneMode.Additive);

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

        if (Time.time - startTime > 0.9) StopRec();
    }

    void OnDestroy()
    {
        StopRec();
    }

    public void StartRecLivePhotos()
    {
        if (isRecording) return;

        uuid = System.Guid.NewGuid().ToString();
        MediaCreator.InitAsMovWithNoAudio(cachePath, "h264", texture.width, texture.height, uuid);
        MediaCreator.Start(startTimeOffset);

        startTime = Time.time;

        isRecording = true;
    }

    private void StopRec()
    {
        if (!isRecording) return;

        MediaCreator.FinishSync();
        MediaSaver.SaveLivePhotos(texture, uuid, cachePath);

        isRecording = false;
    }
}
