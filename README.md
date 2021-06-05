# UnityVideoCreator

Unity iOS Native Plugin to Export Unity Texture and audio to movie file.


# Usage

* Instantiate VideoCreatorUnity
* Set the path of the tmp file and the resolution
  * In this case, 1920x1080

```c#
videoCreatorUnity = new VideoCreatorUnity(Application.temporaryCachePath + "/tmp.mov", true, 1920, 1080);
```

* Start recording

```c#
videoCreatorUnity.StartRecording();
```

* Write Texture

```c#
videoCreatorUnity.Append(texture);
```

* Finish recording

```c#
videoCreatorUnity.FinishRecording();
```

* The video is saved in your album.

# Installation

* Copy `Examples/UnityExample/Assets/Plugin/VideoCreator` to your project
