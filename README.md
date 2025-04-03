Docker image for working with Turtlebot4. The image is based on Ubuntu 22.04.

* Build ROS2 Humble docker image (run the command from the `docker` folder):
    ```
    userid=$(id -u) groupid=$(id -g) docker compose -f humble-tb3_mrc-compose.yml build
    ```    
* Start the container:
    ```
    docker compose -f humble-tb3_mrc-compose.yml run --rm humble-tb3_mrc-docker
    ```

