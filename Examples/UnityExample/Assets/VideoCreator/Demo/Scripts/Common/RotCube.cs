using UnityEngine;

public class RotCube : MonoBehaviour {

    void Start () {

    }
	
	// Update is called once per frame
	void Update () {
        if (this.transform.position.y < 0)
        {
            vy = 0.0f;
            this.transform.position = new Vector3(0, 0, 0);
        }
        else
        {
            vy -= 0.006f;
            this.transform.position += new Vector3(0, vy, 0);
        }

        this.transform.Rotate(2, -3, 4);
    }

    private float vy = 0.0f;
    public void Jump()
    {
        vy += 0.1f;
        this.transform.position += new Vector3(0, vy, 0);
    }

}
