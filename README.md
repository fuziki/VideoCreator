# UnityVideoCreator

* This plugin helps you to implement the recording of wav and mov files in your Unity app.
* Writing textures creates a video, and writing float arrays creates an audio.
* You can easily get support for [AVAssetWriter](https://developer.apple.com/documentation/avfoundation/avassetwriter), a powerful framework created by apple.

# Installation

* Copy `Examples/UnityExample/Assets/Plugin/VideoCreator` to your project

# Features
## movie
* Video
  * Codec
    * [x] h264
    * [x] hevcWithAlpha
  * Source
    * [x] Unity Texture (e.g. RenderTexture, Texture2D, etc)
* Audio
  * Codec
    * [x] aac
  * Source
    * [x] float array
* Container
  * [x] mov
  * [ ] mp4

## audio
* Codec
  * [x] liner
* Source
  * [x] float array
* Container
  * [x] wav

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

## Save to album app (optional)

* If you want to save your recorded videos to an album, you can use MediaSaver to do so.

```c#
MediaSaver.SaveVideo(cachePath);
```

# Examples
## UnityExample
* Example for Unity
* Unity Version: 2020.3.5
* Build for iOS

## NativeExamples
### CrossMetal iOS
* Export Metal Texture to movie file.

### WavExample
* Export PCM data to wav file.

### MovExample
* Export Metal Texture & PCM data to movie file.
