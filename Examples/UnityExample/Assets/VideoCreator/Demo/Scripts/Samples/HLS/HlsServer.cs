using System.Collections.Generic;
using UnityEngine;
using System.Net;
using System.Threading;

public class HlsServer : MonoBehaviour
{

    private Thread listenerThread;
    private readonly HttpListener httpListener = new HttpListener();

    // Start is called before the first frame update
    void Start()
    {
        httpListener.Prefixes.Add("http://*:8080/");
        StartServer();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void StartServer()
    {
        httpListener.Start();
        listenerThread = new Thread(Listen);
        listenerThread.Start();
    }

    private async void Listen()
    {
        while (httpListener.IsListening)
        {
            var context = await httpListener.GetContextAsync();
            ProcessRequest(context);
        }
    }

    public void StopServer()
    {
        listenerThread.Join();
        httpListener.Stop();
    }

    void OnDestroy()
    {
        StopServer();
    }

    private void ProcessRequest(HttpListenerContext context)
    {
        context.Response.StatusCode = 200;

        byte[] data = System.Text.Encoding.UTF8.GetBytes("access http://XXX.XXX.XXX.XXX:8080/index");
        string contentType = "text/plain";

        var path = context.Request.Url.LocalPath;
        switch (path)
        {
            case "/index":
                data = System.Text.Encoding.UTF8.GetBytes(Html);
                contentType = "text/html";
                break;
            case "/hls.m3u8":
                data = System.Text.Encoding.UTF8.GetBytes(M3U8);
                contentType = "application/x-mpegURL";
                break;
            case "/init.mp4":
                data = initData;
                contentType = "video/mp4";
                break;
            default:
                break;
        }
        if(path.StartsWith("/files/sequence"))
        {
            for(int i = 0; i < sequences.Count; i++)
            {
                if (!path.StartsWith($"/files/sequence{sequences[i].sequence}")) continue;
                data = sequences[i].data;
                contentType = "video/iso.segment";
                break;
            }
        }
        Debug.Log($"path: {path}, contentType: {contentType}");

        context.Response.ContentType = contentType;
        context.Response.Close(data, false);
    }

    private int sequence = -1;
    private byte[] initData;
    private readonly List<(int sequence, byte[] data)> sequences = new List<(int sequence, byte[] data)>();

    public void OnSegmentData(byte[] data)
    {
        sequence++;
        if(sequence == 0)
        {
            initData = data;
            return;
        }
        sequences.Add((sequence, data));
        if(sequences.Count > 5)
        {
            sequences.RemoveAt(0);
        } 
    }

    private string Html
    {
        get
        {
            var body = @"
<script src=""https://cdn.jsdelivr.net/npm/hls.js@latest""></script>
<head>
<title> VideoCreator </title>
</ head >
<video id = ""video"" width = ""360"" height = ""240"" autoplay muted></video>
<script>
    var video = document.getElementById('video');
    var videoSrc = 'hls.m3u8';
    if (Hls.isSupported())
    {
        var hls = new Hls();
        hls.loadSource(videoSrc);
        hls.attachMedia(video);
    }
    else if (video.canPlayType('application/vnd.apple.mpegurl'))
    {
        video.src = videoSrc;
    }
</script>
";
            return body;
        }
    }

    private string M3U8
    {
        get
        {
            var durationStr = "1.000";
            string body = @$"#EXTM3U
#EXT-X-TARGETDURATION:1
#EXT-X-VERSION:9
#EXT-X-MEDIA-SEQUENCE:{sequence - 2}
#EXT-X-MAP:URI=""init.mp4""
#EXTINF:{durationStr},
files/sequence{sequence - 2}.m4s
#EXTINF:{durationStr},
files/sequence{sequence - 1}.m4s
#EXTINF:{durationStr},
files/sequence{sequence}.m4s";
            return body;
        }
    }
}

