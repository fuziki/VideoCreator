# VideoCreator

* iOS Native Plugin to Export Texture and pcm to movie file.
* Support .mov, .wav, Live Photos, .png and .jpeg.

# Usage
## Setup
### Setup MediaCreator for mov file (no audio)
* Set the tmp file location as absolute path.
* "h264" or "hevcWithAlpha"
  * If you want to record a video with an alpha channel, you need to specify the "hevcWithAlpha".
* Set video width and height.

```c#
string cachePath = "file://" + Application.temporaryCachePath + "/tmp.mov";
MediaCreator.InitAsMovWithAudio(cachePath, "h264", width, height);
```

### Setup MediaCreator for mov file (with audio)
* In addition to no audio, set the number of channels and sampling rate for audio.

```c#
string cachePath = "file://" + Application.temporaryCachePath + "/tmp.mov";
MediaCreator.InitAsMovWithAudio(cachePath, "h264", texture.width, texture.height, 1, 48_000);
```

### Setup MediaCreator for Live Photos
* In addition to the usual mov, set Content Identifier.

```c#
string uuid = System.Guid.NewGuid().ToString();
string cachePath = "file://" + Application.temporaryCachePath + "/tmp.mov";
MediaCreator.InitAsMovWithAudio(cachePath, "h264", width, height, uuid);
```

### Setup MediaCreator for wav file
* In addition to the number of audio channels and sampling rate, set the Bit Depth.

```c#
string cachePath = "file://" + Application.temporaryCachePath + "/tmp.wav";
MediaCreator.InitAsWav(cachePath, 1, 48000, 32);
```

## Start Recording

* Set a start time in the timeline of the source samples.
* The time unit is microseconds.

```c#
long startTimeOffset = 0;
MediaCreator.Start(startTimeOffset);
```

## Write Texture

* Give a time based on start and any texture.
* The time unit is microseconds.

```c#
Texture texture = Get Texture;
long time = startTimeOffset + Elapsed time from Start;
MediaCreator.WriteVideo(texture, time);
```

## Write Audio PCM

* Give a time based on start and pcm float array.
* The time unit is microseconds.

```c#
float[] pcm = Get PCM float array;
long time = startTimeOffset + Elapsed time from Start;
MediaCreator.WriteAudio(pcm, time);
```

## Finish Recording

* Save recording files synchronously
* This process may take some time.

```c#
MediaCreator.FinishSync();
```

## Save mov to album app (optional)

* If you want to save your recorded videos to an album, you can use MediaSaver to do so.

```c#
MediaSaver.SaveVideo(cachePath);
```

## Save Live Photos to album app

* If you want to save your recorded Live Photos to an album, you can use MediaSaver to do so.
* Set the thumbnail and the same Content Identifier as the video.

```c#
MediaSaver.SaveLivePhotos(texture, uuid, cachePath);
```

## Save Texture to album app

* You can choose the format from "jpeg", "jpg", "heif", and "png".

```c#
MediaSaver.SaveImage(texture, "png");
```
