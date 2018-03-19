# ==================================================================
# Based on Ubuntu-16.04
# ------------------------------------------------------------------
#  C / C++ / Python2 / Python3 / PHP / Golang / NodeJS
# ==================================================================

ARG BASE_IMAGE
FROM ${BASE_IMAGE}
LABEL maintainer "xczh <xczh.me@foxmail.com>"

# ==================================================================
# add files
# ------------------------------------------------------------------

ADD build/user.settings /root/.c9/user.settings
ADD build/ide-run /usr/sbin/
ADD ide-bin/* /usr/local/ide-bin/

# ==================================================================
# prepare
# ------------------------------------------------------------------

RUN APT_INSTALL="apt-get install -y --no-install-recommends" && \
    PIP2_INSTALL="pip2 --no-cache-dir install --upgrade" && \
    PIP3_INSTALL="pip3 --no-cache-dir install --upgrade" && \
    GIT_CLONE="git clone --single-branch --depth 1" && \

    rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get update && \
    chmod a+x /usr/sbin/ide-run && \
    chmod a+x /usr/local/ide-bin/* && \
    echo 'PATH=$PATH:/cloud9/bin:/usr/local/ide-bin' >> /root/.bashrc && \
    echo "alias open='c9 open'" >> /root/.bashrc && \

# ==================================================================
# tools
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        ca-certificates \
        apt-transport-https \
        tzdata \
        wget \
        curl \
        zip \
        htop \
        net-tools \
        inetutils-ping \
        git \
        vim \
        nano \
        && \
    echo 'export LANG="C.UTF-8"' >> /etc/profile && \
    echo "Asia/Shanghai" > /etc/timezone && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \

# ==================================================================
# c AND c++
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        build-essential \
        make \
        cmake \
        gcc \
        g++ \
        && \

# ==================================================================
# python2 AND python3
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        python \
        python-dev \
        python3 \
        python3-dev \
        && \
    curl -L  https://bootstrap.pypa.io/get-pip.py | python2 && \
    curl -L  https://bootstrap.pypa.io/get-pip.py | python3 && \
    $PIP2_INSTALL \
        setuptools \
        virtualenv \
        && \
    $PIP3_INSTALL \
        setuptools \
        virtualenv \
        && \

# ==================================================================
# php
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        php-cli \
        php-json \
        php-mysql \
        php-mcrypt \
        php-soap \
        php-mbstring \
        php-gd \
        php-curl \
        && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \

# ==================================================================
# golang
# ------------------------------------------------------------------

    GOLANG_VER="1.10" && \
    curl -o /tmp/go${GOLANG_VER}.linux-amd64.tar.gz \
        https://dl.google.com/go/go${GOLANG_VER}.linux-amd64.tar.gz && \
    tar -zxf /tmp/go${GOLANG_VER}.linux-amd64.tar.gz -C /usr/local/ && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go && \
    ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt && \
    ln -s /usr/local/go/bin/godoc /usr/local/bin/godoc && \
    rm -f /tmp/go${GOLANG_VER}.linux-amd64.tar.gz && \

# ==================================================================
# node.js
# ------------------------------------------------------------------

    curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        nodejs \
        && \
    ln -s /usr/bin/nodejs /usr/local/bin/node && \
    npm config set registry https://registry.npm.taobao.org && \
    npm install -g http-server && \

# ==================================================================
# openssh AND openssl
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        openssh-server \
        openssl \
        && \
    mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin/PermitRootLogin yes #/' /etc/ssh/sshd_config && \

# ==================================================================
# supervisor
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        supervisor \
        && \
    sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' \
        /etc/supervisor/supervisord.conf && \

# ==================================================================
# cloud9
# ------------------------------------------------------------------

    $GIT_CLONE https://github.com/c9/core.git /cloud9 && \
    /cloud9/scripts/install-sdk.sh && \
    sed -i -e 's_127.0.0.1_0.0.0.0_g' \
        /cloud9/configs/standalone.js && \

# ==================================================================
# c9-codeintel
# see: https://github.com/c9/c9.ide.language.codeintel
# ------------------------------------------------------------------

    virtualenv --python=python2 /root/.c9/python2 && \
    . /root/.c9/python2/bin/activate && \
    mkdir /tmp/codeintel && \
    pip download -d /tmp/codeintel codeintel==0.9.3 && \
    cd /tmp/codeintel && \
    tar xf CodeIntel-0.9.3.tar.gz && \
    mv CodeIntel-0.9.3/SilverCity CodeIntel-0.9.3/silvercity && \
    tar -zcf CodeIntel-0.9.3.tar.gz CodeIntel-0.9.3 && \
    pip install -U --no-index --find-links=/tmp/codeintel codeintel && \
    deactivate && \
    cd /root && \

# ==================================================================
# cleanup
# ------------------------------------------------------------------

    apt-get clean -y && \
    apt-get autoremove -y && \
    npm cache clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache /root/.c9/tmux-* /root/.c9/libevent-* /root/.c9/ncurses-*

# ==================================================================
# add config files
# config must add after APT_INSTALL otherwise will be override
# ------------------------------------------------------------------

ADD conf/supervisord.conf /etc/supervisor/supervisord.conf

# ==================================================================
# meta
# ------------------------------------------------------------------

VOLUME /workspace

EXPOSE 80

ENV C9_AUTH webide:webide

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]