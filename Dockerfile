FROM ubuntu:22.04

RUN apt-get update

# General dependencies
RUN apt-get install -y \
  bear \
  make \
  git \
  mercurial \
  wget \
  vim \
  autoconf \
  bzr \
  cvs \
  unrar \
  build-essential \
  clang \
  valgrind \
  gsl-bin \
  libgsl-dev \
  flex \
  bison \
  libfl-dev \
  tcpdump \
  sqlite \
  sqlite3 \
  libsqlite3-dev \
  libxml2 \
  libxml2-dev \
  vtun \
  unzip \
  lxc \
  clangd \
  tar \
  curl \
  libbz2-dev \
  libreadline-dev \
  libssl-dev \
  libffi-dev \
  liblzma-dev \
  zlib1g-dev

# QT5 components
RUN apt-get install -y \
  qtbase5-dev

# Python3 components (updated for Ubuntu 22.04)
RUN apt-get update && apt-get install -y \
  python3 \
  python3-dev \
  python3-setuptools \
  python3-pip \
  python3-wheel \
  python3-requests \
  python3-gi \
  python3-gi-cairo \
  python3-pygraphviz \
  python3-distro \
  gir1.2-gtk-3.0 \
  cmake \
  libc6-dev \
  gcc \
  g++ 
  
# Link python3 to python
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install Python dependencies
RUN pip3 install pybindgen

# Install pyenv and setup environment
RUN curl https://pyenv.run | bash && \
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc && \
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc && \
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc

# Setup environment variables for pyenv
ENV PYENV_ROOT=/root/.pyenv
ENV PATH=$PYENV_ROOT/bin:$PATH
ENV PATH=$PYENV_ROOT/shims:$PATH

# Install Python 3.6 and create virtualenv
RUN eval "$(pyenv init -)" && \
    pyenv install 3.6.15 && \
    pyenv global 3.6.15 && \
    pyenv virtualenv 3.6.15 venv3.6

# Create project directory
RUN mkdir -p /src

# Copy and extract ns-allinone-3.30.1
COPY ns-allinone-3.30.1.tar.bz2 /src/
RUN tar -xjf /src/ns-allinone-3.30.1.tar.bz2 -C /src/ && \
    rm /src/ns-allinone-3.30.1.tar.bz2

# Copy ns-3-leo project placing it under ns-3.30.1/contrib/leo
COPY ns-3-leo-main /src/ns-allinone-3.30.1/ns-3.30.1/contrib/leo

# Copy and extract GPSR module for ns-3.30.1
COPY ns-3-gpsr.tar.bz2 /src/
RUN tar -xjf /src/ns-3-gpsr.tar.bz2 -C /src/ns-allinone-3.30.1/ns-3.30.1/src/ && \
    rm /src/ns-3-gpsr.tar.bz2

# Copy and extract location-service module for ns-3.30.1 that is needed by gpsr module
COPY ns-3-location-service.tar.bz2 /src/
RUN tar -xjf /src/ns-3-location-service.tar.bz2 -C /src/ns-allinone-3.30.1/ns-3.30.1/src/ && \
    rm /src/ns-3-location-service.tar.bz2

WORKDIR /src/ns-allinone-3.30.1

# Build NS-3 with Python bindings
RUN . /root/.pyenv/versions/venv3.6/bin/activate && \
    ./build.py --enable-examples --enable-tests CXXFLAGS="-std=c++17"

WORKDIR /src/ns-allinone-3.30.1/ns-3.30.1

RUN ./waf --version && ./waf --run first
# Cleanup
#RUN apt-get clean && \
#  rm -rf /var/lib/apt/lists/*