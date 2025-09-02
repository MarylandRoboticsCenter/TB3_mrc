This repository provides a Docker image for working with Turtlebot3 robots. The image is based on Ubuntu 22.04 and preconfigured for development using ROS2 Humble.

## Overview

* The container includes two ROS2 workspaces: ROS2 driver workspace (`tb3_ros_driver`) and development workspace (`tb3_ws`).
* `tb3_ros_driver` workspace contains TB3 ROS2 drivers and Gazebo simulation packages. Don't use this workspace to add or edit ROS2 packages when running the container since all changes will be temporary. To make permanent changes, modify the Dockerfile and rebuild the image.
* `tb3_ws` is the primary workspace for development when running the docker container. Two folders from the host machine are bind-mounted into the container:
  * `src` folder in the root of this repository is mounted into the container as `src` folder of `tb3_ws` workspace. This allows to edit the code on the host system and compile it inside the container, while ensuring that all changes persist even after the container is stopped.
  * `config` folder in the root of this repository is mounted into the container as `config` folder of `tb3_ws` workspace. This allows to easily edit the configuration parameters without rebuilding thge image or restarting the container.

## Workflow
* Build Docker image (run the command from the `docker` folder):
    ```
    userid=$(id -u) groupid=$(id -g) docker compose -f humble-tb3_mrc-compose.yml build
    ```
* Start the container (run the command from the `docker` folder):
    ```
    docker compose -f humble-tb3_mrc-compose.yml run --rm humble-tb3_mrc-docker
    ```
  On PCs with nvidia GPUs run the following command instead:
    ```
    docker compose -f humble-tb3_mrc-nvidia-compose.yml run --rm humble-tb3_mrc-docker
    ```    
* Once inside the container, use `tmux` to manage multiple panes:
  * `tmux`      # Start a new session
  * `Ctrl+A b`  # Split horizontally
  * `Ctrl+A v`  # Split vertically
* Use your preferred editor on the host machine to modify source code and config files. 
* Inside the container:
  * Compile your packages in `tb3_ws` workspace using `colcon build`.
  * Start ROS2 nodes using `ros2 run ...` or `ros2 launch ...`
  
Used resources:
1. https://github.com/2b-t/docker-for-robotics
2. https://github.com/ROBOTIS-GIT/turtlebot3 - Turtlebot3 official repository
3. https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/#overview - Turtlebot3 documentation website
