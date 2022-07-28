FROM waggle/plugin-base:1.1.1-base
LABEL description="Waggle base image containing ROS2 foxy."
LABEL maintainer="Sage Waggle Team <sage-waggle@sagecontinuum.org>"
LABEL url="https://github.com/waggle-sensor/plugin-base-images/tree/master/base-ros2"

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV ROS_DISTRO=foxy
ENV ROS_ROOT=/opt/ros/${ROS_DISTRO}
ENV ROS_PYTHON_VERSION=3
ENV ROS_WS=/root/overlay_ws

# install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg2 \
    lsb-release \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# install ros2 foxy-base
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - \
    && sh -c 'echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list' \
    && apt-get update \
    && apt-get install -y ros-foxy-ros-base \
    && rm -rf /var/lib/apt/lists/*

# sourcing underlay
RUN echo "source $ROS_ROOT/setup.bash" >> ~/.bashrc

# creating, downloading resource directories ros packages and sourcing an overlay
RUN mkdir -p $ROS_WS/src/demo \
    && mkdir -p $ROS_WS/src/demo_interfaces
    
WORKDIR /root
COPY resources/robot_config.yaml /root/robot_config.yaml
COPY resources/protocol_config.yaml /root/protocol_config.yaml

WORKDIR $ROS_WS
#COPY demo/ src/demo
#COPY demo_interfaces/ src/demo_interfaces
RUN git clone -b demo https://github.com/kjwelbeck3/OT2_actions.git \
    && mv OT2_actions src

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-colcon-common-extensions \
    build-essential \
    && rm -rf /var/lib/apt/lists/*
SHELL ["/bin/bash", "-c"]
RUN source $ROS_ROOT/setup.bash && colcon build --symlink-install && source $ROS_WS/install/setup.bash
RUN echo "source $ROS_WS/install/setup.bash" >> ~/.bashrc


# Installing network and ping tools
RUN apt-get update && apt-get install --no-install-recommends -y \ 
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*
    
# setup entrypoint
COPY ./ros_entrypoint.sh /
ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
