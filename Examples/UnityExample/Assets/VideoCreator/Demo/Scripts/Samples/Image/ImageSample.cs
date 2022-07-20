using System.Collections;
using System.Linq;
using UnityEngine;
using UnityEngine.SceneManagement;
using VideoCreator;

public class ImageSample : MonoBehaviour
{
    public RenderTexture texture = null;

    // Start is called before the first frame update
    IEnumerator Start()
    {
        Application.targetFrameRate = 30;
        AsyncOperation asyncLoad = SceneManager.LoadSceneAsync("Common", LoadSceneMode.Additive);
        while (!asyncLoad.isDone)
        {
            yield return null;
        }
        Scene scene = SceneManager.GetSceneByName("Common");
        var cameraObj = scene.GetRootGameObjects().First(obj => obj.name == "RecordingCamera");
        var camera = cameraObj.GetComponent<Camera>();
        texture = camera.targetTexture;
        Debug.Log($"texture: {texture}");
    }

    public void TakePng()
    {
        MediaSaver.SaveImage(texture, "png");
    }

    public void TakeJpeg()
    {
        MediaSaver.SaveImage(texture, "jpeg");
    }

    public void TakeHeif()
    {
        MediaSaver.SaveImage(texture, "heif");
    }
}
