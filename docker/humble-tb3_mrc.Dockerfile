##############
# modified full ubuntu image #
##############
FROM osrf/ros:humble-desktop AS humble-mod_desktop

# Set default shell
SHELL ["/bin/bash", "-c"]

WORKDIR ${HOME}

ENV DEBIAN_FRONTEND=noninteractive

# Basic setup
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends --allow-unauthenticated \
    build-essential \
    curl \
    g++ \
    git \
    ca-certificates \
    make \
    cmake \
    automake \
    autoconf \
    bash-completion \
    iproute2 \
    iputils-ping \
    pkg-config \
    libxext-dev \
    libx11-dev \
    mc \
    mesa-utils \
    nano \
    software-properties-common \
    sudo \
    tmux \
    tzdata \
    xclip \
    x11proto-gl-dev && \
    sudo rm -rf /var/lib/apt/lists/*

# Set datetime and timezone correctly
RUN sudo ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo '$TZ' | sudo tee -a /etc/timezone

ENV DEBIAN_FRONTEND=dialog

##############
# Aux ROS2 packages #
##############
FROM humble-mod_desktop AS humble-dev

# Install ROS packages
RUN sudo apt-get update && sudo apt-get install -y \
    ros-dev-tools \
    ros-humble-xacro \
    python-is-python3 \
    python3-pip \
    python3-colcon-common-extensions python3-vcstool && \
    sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# upgrading colcon package to fix symlink issues
RUN pip3 install setuptools==58.2.0


##############
# user with matching uid and gid#
##############
FROM humble-dev AS humble-user

ARG WS_DIR="dir_ws"
ARG USERNAME=user
ARG userid=1111
ARG groupid=1111
ARG PW=user@123
ARG ROS_DOMAIN_ID=1
ARG ROS_LOCALHOST_ONLY=1

RUN groupadd -g ${groupid} -o ${USERNAME}
RUN useradd --system --create-home --home-dir /home/${USERNAME} --shell /bin/bash --uid ${userid} -g ${groupid} --groups sudo,video ${USERNAME} && \
    echo "${USERNAME}:${PW}" | chpasswd && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

ENV USER=${USERNAME} \
    WS_DIR=${WS_DIR} \
    LANG=en_US.UTF-8 \
    HOME=/home/${USERNAME} \
    XDG_RUNTIME_DIR=/run/user/${userid} \
    TZ=America/New_York

USER ${USERNAME}
WORKDIR ${HOME}

# custom Bash prompt
RUN { echo && echo "PS1='\[\e]0;\u \w\a\]\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] \\\$ '" ; } >> .bashrc

RUN sudo mkdir -p -m 0700 /run/user/${userid} && \
    sudo chown ${USERNAME}:${USERNAME} /run/user/${userid}

# Setup tmux config
ADD --chown=${USERNAME}:${USERNAME} https://raw.githubusercontent.com/MarylandRoboticsCenter/someConfigs/refs/heads/master/.tmux_K.conf $HOME/.tmux.conf


#####################
# ROS2 workspace #
#####################
FROM humble-user AS humble-user_ws

WORKDIR ${HOME}

# Create workspace folder
RUN source /opt/ros/humble/setup.bash && \
    mkdir -p $HOME/${WS_DIR}/src && \
    cd $HOME/${WS_DIR} && \
    colcon build --symlink-install --executor sequential

RUN echo >> $HOME/.bashrc && \
    echo 'source /opt/ros/humble/setup.bash' >> $HOME/.bashrc && \
    echo 'source /usr/share/colcon_cd/function/colcon_cd.sh' >> $HOME/.bashrc && \
    echo 'source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash' >> $HOME/.bashrc && \
    echo >> $HOME/.bashrc && \
    echo "source $HOME/${WS_DIR}/config/tb3_setup.bash" >> $HOME/.bashrc
    

#####################
# TB3 ROS2 packages#
#####################
FROM humble-user_ws AS humble-tb3_mrc

# installing aux TB3 packages
RUN sudo apt-get update && sudo apt-get install -y \
    ros-humble-gazebo-* \
    ros-humble-cartographer \
    ros-humble-cartographer-ros  \
    ros-humble-navigation2 \
    ros-humble-nav2-bringup && \
    sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# installing TB3 packages
RUN source /opt/ros/humble/setup.bash && \
    mkdir -p ~/tb3_ros_driver/src && \
    cd ~/tb3_ros_driver/src && \
    git clone -b humble https://github.com/ROBOTIS-GIT/DynamixelSDK.git && \
    git clone -b humble https://github.com/ROBOTIS-GIT/turtlebot3_msgs.git && \
    git clone -b humble https://github.com/ROBOTIS-GIT/turtlebot3.git && \
    cd ~/tb3_ros_driver && \
    colcon build -j2 --symlink-install

RUN echo "source $HOME/tb3_ros_driver/install/setup.bash" >> $HOME/.bashrc

CMD /bin/bash
