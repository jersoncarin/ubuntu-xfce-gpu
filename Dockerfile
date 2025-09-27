FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Manila

ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV NVIDIA_VISIBLE_DEVICES=all

RUN mkdir -p /tmp/runtime-cuda && \
    chown 1000:1000 /tmp/runtime-cuda

ENV XDG_RUNTIME_DIR=/tmp/runtime-cuda
ENV __GLX_VENDOR_LIBRARY_NAME=nvidia
ENV __NV_PRIME_RENDER_OFFLOAD=1

COPY ./scripts/nvidia_icd.json /etc/vulkan/icd.d
ENV VK_ICD_FILENAMES=/etc/vulkan/icd.d/nvidia_icd.json

# Update the system and install openssh for SSH server
RUN apt-get update && apt-get install -y openssh-server

# Install XFCE and other goodies
RUN apt-get install -y \
    dbus-x11 \
    xfce4 \
    xfce4-goodies\
    xfce4-clipman-plugin \
    xfce4-cpugraph-plugin \
    xfce4-netload-plugin \
    xfce4-screenshooter \
    xfce4-taskmanager \
    xfce4-terminal \
    xfce4-xkb-plugin \
    mesa-utils \
    git \
    wget \
    curl \
    sudo \
    nano \
    software-properties-common \
    apt-transport-https \
    neofetch

# Install TurboVNC
RUN wget https://github.com/TurboVNC/turbovnc/releases/download/3.2/turbovnc_3.2_amd64.deb \
    && apt-get update \
    && apt-get install -y ./turbovnc_3.2_amd64.deb \
    && rm -f turbovnc_3.2_amd64.deb \
    && rm -rf /var/cache/apt /var/lib/apt/lists/*

# Install VirtualGL
RUN wget https://github.com/VirtualGL/virtualgl/releases/download/3.1.3/virtualgl_3.1.3_amd64.deb \
    && apt-get update \
    && apt-get install -y ./virtualgl_3.1.3_amd64.deb \
    && rm -f virtualgl_3.1.3_amd64.deb \
    && rm -rf /var/cache/apt /var/lib/apt/lists/*

# Create SSH folder for SSH Service
RUN mkdir /var/run/sshd

# Enable password authentication in the SSH configuration
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Disable root login via SSH
RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Install Vulkan
RUN apt-get update \
    && apt-get install -y \
    libxext6 \
    libvulkan1 \
    libvulkan-dev \
    vulkan-tools

# Copy this systemctl to the docker container build image
# this systemctl is fake and use for some reasons
COPY ./scripts/systemd/systemctl3.py /usr/bin/systemctl
RUN test -e /bin/systemctl || ln -sf /usr/bin/systemctl /bin/systemctl

# Install Webots
RUN wget https://github.com/cyberbotics/webots/releases/download/R2025a/webots_2025a_amd64.deb \
    && apt-get update \
    && apt-get install -y ./webots_2025a_amd64.deb \
    && rm -f webots_2025a_amd64.deb \
    && rm -rf /var/cache/apt /var/lib/apt/lists/*

# Install Firefox from Mozilla's APT repo
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg \
       | tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
       > /etc/apt/sources.list.d/mozilla.list \
    && printf "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n" \
       > /etc/apt/preferences.d/mozilla \
    && apt-get update \
    && apt-get install -y --no-install-recommends firefox \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies and Tailscale automatically
RUN apt-get update && \
    apt-get install -y curl gnupg2 && \
    curl -fsSL https://tailscale.com/install.sh | sh && \
    rm -rf /var/lib/apt/lists/*

# Install vscode
RUN apt-get update && \
    apt-get install -y wget apt-transport-https && \
    wget -O vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" && \
    apt install -y ./vscode.deb && \
    rm vscode.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# Copy the start up script
COPY ./scripts/start.sh /usr/bin/
RUN mv /usr/bin/start.sh /usr/bin/run.sh && chmod +x /usr/bin/run.sh

# transfer the vnc server
COPY ./scripts/vnc.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/vnc.sh

ENTRYPOINT ["/usr/bin/run.sh"]