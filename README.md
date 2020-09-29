# はじめに
## 環境
* Unity: 2018.2.5
* Xcode: 10.2.1
* iOS: 12.4
* リポジトリ: https://github.com/fuziki/VideoCreator

# 目的
* Unityのワールドは下の写真の通り
* メインカメラの映像を画面に表示する
* 録画カメラの映像と、本体のマイクの音声を.mov形式で録画し、写真アプリに保存する
<img width="636" alt="スクリーンショット 2019-08-17 14.32.39.png" src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/214313/844a1a25-d8e4-e907-aea0-006ab65b3aa5.png">

# 実際に動作している様子
<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">Unityの録画機能を作りました。<br>ボタンは左から「スタート」「ジャンプ」「ストップ」です。<br>動画はmp4として、写真に保存されます！<a href="https://twitter.com/hashtag/Unity?src=hash&amp;ref_src=twsrc%5Etfw">#Unity</a> <a href="https://t.co/2NKoExxAEY">pic.twitter.com/2NKoExxAEY</a></p>&mdash; ふじき (@fzkqi) <a href="https://twitter.com/fzkqi/status/1162661022248816640?ref_src=twsrc%5Etfw">August 17, 2019</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

# Code
## Unity(C#)
### IVideoCreatorUnity.cs
``` IVideoCreatorUnity.cs
public interface IVideoCreatorUnity { 
    bool IsRecording
    {
        get;
    }
    void StartRecording();
    void Append(Texture texture);
    void FinishRecording();
}
```

### VideoCreatorUnity.cs
* tmpFilePath: キャッシュの動画のURL
* enableAudio: マイクのon / off
* videoWidth: videoの横幅
* videoHeight: videoの高さ

``` VideoCreatorUnity.cs
public class VideoCreatorUnity: IVideoCreatorUnity
{ 
    private IVideoCreatorUnity videoCreator = null;
    public VideoCreatorUnity(string tmpFilePath, bool enableAudio, int videoWidth, int videoHeight)
    {
#if UNITY_EDITOR
        videoCreator = null;
#elif UNITY_IOS
        videoCreator = VideoCreatorUnityIOS(tmpFilePath, enableAudio, videoWidth, videoHeight);
#endif
    }
    public bool IsRecording
    {
        get
        {
            if (videoCreator == null) return false;
            return videoCreator.IsRecording;
        }
    }
    //~~ 中略 ~~
}
```
### VideoCreatorUnityIOS.cs
* NativePluginのVideoCreatorUnity.mmの関数をdllimportを使って呼び出す。

``` VideoCreatorUnityIOS.cs
public class VideoCreatorUnityIOS : IVideoCreatorUnity
{
    [DllImport("__Internal")]
    private static extern IntPtr videoCreator_init(string tmpFilePath, bool enableAudio, int videoWidth, int videoHeight);
    [DllImport("__Internal")]
    private static extern bool videoCreator_isRecording(IntPtr creator);
    [DllImport("__Internal")]
    private static extern void videoCreator_startRecording(IntPtr creator);
    [DllImport("__Internal")]
    private static extern void videoCreator_append(IntPtr creator, IntPtr mtlTexture);
    [DllImport("__Internal")]
    private static extern void videoCreator_finishRecording(IntPtr creator);
    [DllImport("__Internal")]
    private static extern void videoCreator_release(IntPtr creator);

    private IntPtr creatorObject;
    public VideoCreatorUnityIOS(string tmpFilePath, bool enableAudio, int videoWidth, int videoHeight)
    {
        creatorObject = videoCreator_init(tmpFilePath, enableAudio, videoWidth, videoHeight);
    }

    ~VideoCreatorUnityIOS()
    {
        videoCreator_release(creatorObject);
    }
    //~~ 中略 ~~
}
```

## iOS(Objective-C)
### VideoCreatorUnity.mm
* VideoCreator.frameworkのVideoCreatorUnityオブジェクトの生成/破棄/メソッドを呼び出す。
* VideoCreatorUnityはMTLTextureのpixelFormatとしてMTLPixelFormatBGRA8Unorm_sRGBを期待しているため、変換して渡します。

```objc:VideoCreatorUnity.mm
#import <VideoCreator/VideoCreator-Swift.h>

extern "C" {
    VideoCreatorUnity* videoCreator_init(char* tmpFilePath, bool enableAudio, int videoWidth, int videoHeight);
    bool videoCreator_isRecording(VideoCreatorUnity* creator);
    void videoCreator_startRecording(VideoCreatorUnity* creator);
    void videoCreator_append(VideoCreatorUnity* creator, unsigned char* mtlTexture);
    void videoCreator_finishRecording(VideoCreatorUnity* creator);
    void videoCreator_release(VideoCreatorUnity* creator);
}

VideoCreatorUnity* videoCreator_init(char* tmpFilePath, bool enableAudio, int videoWidth, int videoHeight) {
    VideoCreatorUnity* creator =
    [[VideoCreatorUnity alloc] initWithTmpFilePath: [NSString stringWithUTF8String: tmpFilePath]
                                         enableMic: enableAudio
                                        videoWidth: videoWidth
                                       videoHeight: videoHeight];
    CFRetain((CFTypeRef)creator);
    return creator;
}

bool videoCreator_isRecording(VideoCreatorUnity* creator) {
    return [creator isRecording];
}

void videoCreator_startRecording(VideoCreatorUnity* creator) {
    [creator startRecording];
}

void videoCreator_append(VideoCreatorUnity* creator, unsigned char* mtlTexture) {
    id<MTLTexture> tex = (__bridge id<MTLTexture>) (void*) mtlTexture;
    if (tex.pixelFormat != MTLPixelFormatBGRA8Unorm_sRGB) {
        tex = [tex newTextureViewWithPixelFormat: MTLPixelFormatBGRA8Unorm_sRGB];
    }
    [creator appendWithMtlTexture: tex];
}

void videoCreator_finishRecording(VideoCreatorUnity* creator) {
    [creator finishRecording];
}

void videoCreator_release(VideoCreatorUnity* creator) {
    CFRelease((CFTypeRef)creator);
}
```

# さいごに
* VideoCreator.frameworkの中身はAVAssetWriterです。
* windows/macOSで使えるmp4保存するには→[unity3d-jp/FrameCapturer](https://github.com/unity3d-jp/FrameCapturer)
