using UnityEngine;
using UnityEngine.SceneManagement;

public class MainFlow : MonoBehaviour
{
    public void PresentImageSample()
    {
        SceneManager.LoadScene("ImageSample", LoadSceneMode.Single);
    }

    public void PresentMovSample()
    {
        SceneManager.LoadScene("MovSample", LoadSceneMode.Single);
    }

    public void PresentLivePhotosSample()
    {
        SceneManager.LoadScene("LivePhotosSample", LoadSceneMode.Single);
    }

    public void PresentHlsSample()
    {
        SceneManager.LoadScene("HlsSample", LoadSceneMode.Single);
    }

    public void Close()
    {
        SceneManager.LoadScene("Main", LoadSceneMode.Single);
    }
}
