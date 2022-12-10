# to build, for exemple, run: 
# `username=mine groupname=ours docker run -d -i`
FROM Ubuntu:latest AS kindtek/dbp:essential
ARG username
ARG groupname
RUN apt-get update -yq && \
apt-get upgrade && \
apt-get install -y build-essential sudo && \
addgroup --system --gid 1000 ${group:-dev} && \
adduser --system --home /home/${username:-dev0} --shell /bin/bash --uid 1000 --gid 1000 --disabled-password ${username:-dev0} 
# biggest headache saver of all time - https://www.tecmint.com/cdir-navigate-folders-and-files-on-linux/
RUN sudo apt install python3 python3-pip && \
pip3 install cdir --user
RUN echo "alias cdir='source cdir.sh'" >> ~/.bashrc && \
source ~/.bashrc

# no time for passwords since this is a dev environment but a sudo guardrail is nice
sudo usermod -aG sudo ${username:-dev0} 

echo -e "[user]\ndefault=${username:-dev0}" >> /etc/wsl.conf
sudo passwd -d ${username:-dev0}

FROM kindtek/dbp:essential AS kindtek/dbp:git
RUN sudo apt-get update && \
apt-get install git gh

FROM kindtek/dbp:git AS kindtek/dbp:docker
# https://docs.docker.com/engine/install/ubuntu/
RUN sudo apt-get update &&  \
apt-get install ca-certificates curl gnupg lsb-release
RUN sudo mkdir -p /etc/apt/keyrings && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
