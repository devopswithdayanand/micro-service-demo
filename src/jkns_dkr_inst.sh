#! /bin/bash

#install java-17
sudo apt update
sudo apt install openjdk-17-jdk -y

#install jenkins
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins -y

#install docker and add jenkins to docker group
sudo apt install docker.io -y
sudo usermod -aG docker jenkins
sudo newgrp docker
