# VideoCreator

* This plugin helps you to implement the recording of wav and mov files in your Unity app.
* Writing textures creates a video, and writing float arrays creates an audio.
* You can get support for [AVAssetWriter](https://developer.apple.com/documentation/avfoundation/avassetwriter), a powerful framework created by apple.

![example](docs/videos/example.gif)  

# Installation

* Download VideoCreator.unitypakcage from [Releases](https://github.com/fuziki/VideoCreator/releases) and install it in your project.

# Features

<details>
<summary>Export Video File</summary>

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
  * [x] Live Photos
</details>

<details>
<summary>HLS(HTTP Live Streaming)</summary>

* Video
  * Codec
    * [x] h264
  * Source
    * [x] Unity Texture (e.g. RenderTexture, Texture2D, etc)
* Audio
  * Codec
    * [x] aac
  * Source
    * [x] float array
* Manifesto
  * [x] HLS
</details>

# Environment
## Xcode
* check [.github/workflows/test.yml#L17](.github/workflows/test.yml#L17)

## Unity
* check [Examples/UnityExample/ProjectSettings/ProjectVersion.txt](Examples/UnityExample/ProjectSettings/ProjectVersion.txt)

# Examples for Unity
## Save Image (png, jpeg, heif)

* check [ImageSample.cs](Examples/UnityExample/Assets/VideoCreator/Demo/Scripts/Samples/Image/ImageSample.cs)

## Save Video (mov)

* check [MovSample.cs](Examples/UnityExample/Assets/VideoCreator/Demo/Scripts/Samples/Mov/MovSample.cs)

## Live Photos

* check [LivePhotsSample.cs](Examples/UnityExample/Assets/VideoCreator/Demo/Scripts/Samples/LivePhots/LivePhotsSample.cs)

## HLS(HTTP Live Streaming)

* check [HlsSample.cs](Examples/UnityExample/Assets/VideoCreator/Demo/Scripts/Samples/HLS/HlsSample.cs)

# Build Custom Framework

This is the command to build the UnityVideoCreator.framework.

> make framework

Replace Build/VideoCreator.framework with VideoCreator/Plugins/iOS/UnityVideoCreator.framework.

# References
* [Record Video on Unity iOS App](https://medium.com/@f_yuki/unity-record-video-on-ios-4f4c7defa924)
* [Make Video with Alpha Channel on iOS](https://medium.com/@f_yuki/ios-make-video-with-alpha-channel-d83a2cefe69c)
* [Save Live Photos from mov & jpeg on iOS App](https://medium.com/@f_yuki/save-live-photos-from-mov-jpeg-on-ios-app-ff8c4f9045f1)
