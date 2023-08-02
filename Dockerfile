FROM python:3.9.16-slim
MAINTAINER alvin

ARG user=docker
ARG local_package=utils_thisbuild
ARG github=workspace 
#vscode server 1.54.2
ARG vscommit=fd6f3bce6709b121a895d042d343d71f317d74e7

# udpate timezone
RUN apt-get update \
    &&  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata

RUN TZ=Asia/Taipei \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata 

# install necessary ubuntu application
RUN apt-get update && apt-get install -y \
    apt-utils sudo vim zsh curl git make unzip \
    wget openssh-server rsync iproute2\
    powerline fonts-powerline 

# install https://github.com/openai/gym mention package
RUN apt-get install -y libglu1-mesa-dev libgl1-mesa-dev \
    libosmesa6-dev xvfb ffmpeg curl patchelf \
    libglfw3 libglfw3-dev cmake zlib1g zlib1g-dev swig

# docker account
RUN useradd -m ${user} && echo "${user}:${user}" | chpasswd && adduser ${user} sudo;\
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;\
    chmod 777 /etc/ssh/sshd_config; echo 'GatewayPorts yes' >> /etc/ssh/sshd_config; chmod 644 /etc/ssh/sshd_config

# change workspace
USER ${user}
WORKDIR /home/${user}

# oh-my-zsh setup
ARG omzthemesetup="POWERLEVEL9K_MODE=\"nerdfont-complete\"\n\
ZSH_THEME=\"powerlevel9k\/powerlevel9k\"\n\n\
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(ip pyenv virtualenv context dir vcs)\n\
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs history time)\n\
POWERLEVEL9K_VIRTUALENV_BACKGROUND=\"green\"\n\
POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW=true\n\
POWERLEVEL9K_PYENV_BACKGROUND=\"orange1\"\n\
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND=\"white\"\n\
POWERLEVEL9K_PYTHON_ICON=\"\\U1F40D\"\n"

# ssh/zsh plugin
RUN cd ~/ ; mkdir .ssh ;\
    sudo mkdir /var/run/sshd ;\
    sudo sed -ri 's/session required pam_loginuid.so/#session required pam_loginuid.so/g' /etc/pam.d/sshd ;\
    sudo ssh-keygen -A ;\
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true ;\
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting ;\
    git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k ;\
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ;\
    git clone https://github.com/davidparsson/zsh-pyenv-lazy.git ~/.oh-my-zsh/custom/plugins/pyenv-lazy ;\
    #echo "source ~/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc ;\
    sed -i -r "1s/^/export TERM=\"xterm-256color\"\n/" ~/.zshrc ;\
    sed -i -r "2s/^/LC_ALL=\"en_US.UTF-8\"\n/" ~/.zshrc ;\
    sed -i -r "s/^plugins=.*/plugins=(git zsh-autosuggestions virtualenv screen pyenv-lazy)/" ~/.zshrc ;\
    sed -i -r "s/^ZSH_THEM.*/${omzthemesetup}/" ~/.zshrc ;\
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/SourceCodePro.zip ;\
    unzip SourceCodePro.zip -d ~/.fonts ;\
    fc-cache -fv  ;\
    sudo chsh -s $(which zsh) ${user}

# fix bug on Debian 11, ssh to zsh, POWERLEVEL9K  print_icon issue
# ref: https://stackoverflow.com/questions/2499794/how-to-fix-a-locale-setting-warning-from-perl
RUN sudo apt-get upgrade -y ;\
    sudo apt-get install locales -y;\
    sudo localedef -i en_US -f UTF-8 en_US.UTF-8

# vscode server part
RUN curl -sSL "https://update.code.visualstudio.com/commit:${vscommit}/server-linux-x64/stable" -o /home/${user}/vscode-server-linux-x64.tar.gz;\
    mkdir -p ~/.vscode-server/bin/${vscommit};\
    tar zxvf /home/${user}/vscode-server-linux-x64.tar.gz -C ~/.vscode-server/bin/${vscommit} --strip 1;\
    touch ~/.vscode-server/bin/${vscommit}/0

# pytroch and CV related package
RUN python -m pip install --user torch==1.13.1;\
    python -m pip install --user torchvision==0.14;\
    python -m pip install --user numpy==1.20.0
 
ADD id_rsa*.pub /home/${user}/.ssh/authorized_keys

ENTRYPOINT sudo service ssh restart && zsh
                    

