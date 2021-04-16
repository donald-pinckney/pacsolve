# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "hashicorp/bionic64"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    set -x

    # Install Python 3.9
    apt-get update > /dev/null 2>&1
    add-apt-repository -y ppa:deadsnakes/ppa > /dev/null 2>&1
    apt-get update > /dev/null 2>&1
    apt-get install -y python3.9 python3.9-venv python3.9-dev > /dev/null 2>&1
    
    # Install pip
    apt-get install -y python3-pip > /dev/null 2>&1
    python3.9 -m pip install --upgrade pip > /dev/null 2>&1
    python3.9 -m pip install --upgrade setuptools > /dev/null 2>&1
    python3.9 -m pip install --upgrade distlib > /dev/null 2>&1
    
    # Install Swift dependencies
    apt-get install -y \
          binutils \
          git \
          libc6-dev \
          libcurl4 \
          libedit2 \
          libgcc-5-dev \
          libpython2.7 \
          libsqlite3-0 \
          libstdc++-5-dev \
          libxml2 \
          pkg-config \
          tzdata \
          zlib1g-dev > /dev/null 2>&1
  SHELL
  
  
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    set -x

    # Install node
    curl -s -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash > /dev/null 2>&1

    set +x
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    set -x

    nvm install node > /dev/null 2>&1

    # Install yarn
    npm install -g yarn > /dev/null 2>&1
    
    # Install verdaccio
    npm install -g verdaccio > /dev/null 2>&1
    
    # Install rust / cargo
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y > /dev/null 2>&1
    
    # Install Swift
    wget --quiet https://swift.org/builds/swift-5.3.3-release/ubuntu1804/swift-5.3.3-RELEASE/swift-5.3.3-RELEASE-ubuntu18.04.tar.gz
    tar xzf swift-5.3.3-RELEASE-ubuntu18.04.tar.gz
    echo 'export PATH=$HOME/swift-5.3.3-RELEASE-ubuntu18.04/usr/bin:"${PATH}"' >> ~/.profile

    # Clone repo
    git clone https://github.com/donald-pinckney/dependency-runner > /dev/null 2>&1
  SHELL

  config.vm.provision "shell", reboot: true, inline: <<-SHELL
    echo "Done, rebooting now"
  SHELL

  config.vm.synced_folder ".", "/vagrant", disabled: true
end
