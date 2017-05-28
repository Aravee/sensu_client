#!/bin/bash

#Getting the HOSTNAME & IPADDRESS OF CLIENT MACHINES.
address=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
echo -ne "\e[31mPlease enter the hostname = "
read hostname

#DISPLAYING THE HOSTNAME
echo -e "\e[32mYour host name is - $hostname \n\n"
sleep 2

#FINDING THE OPERATING SYSTEM
os=$(uname -a | awk '{print $4}' | cut -c5-10)

if [[ $os == "Ubuntu" ]];
then
	echo -e "\e[32m \t\t\t\t System is running on Debian Based Operating System...!\n\n"
	echo -e "\e[31m ################################---- Installing Sensu for - $os ----#######################################\n\n"

	#ADDING THE SENSU REPOS FOR UBUNTU AND BEGIN INSTALLATION
	echo -e "\e[32m \t\t\t\t\t Adding Sensu Repo For Ubuntu...! -Done\n\n"
	sleep 1
	sudo wget -q https://sensu.global.ssl.fastly.net/apt/pubkey.gpg -O- | sudo apt-key add -
	sudo echo "deb https://sensu.global.ssl.fastly.net/apt sensu main" | sudo tee /etc/apt/sources.list.d/sensu.list
	sudo apt-get update && sudo apt-get install -y sensu
	sleep 2
	#CREATING CONF's AND ADDING THE CONFIGURATIONS
	#Edit the subsriptions and handlers as per how is configured in the server
	echo -e "\e[32m\n\n \t\t\t\t Adding the client.json & rabbitmq.json files with their configurations...! - Done \n\n"
	sleep 1
	sudo touch /etc/sensu/conf.d/client.json && sudo touch /etc/sensu/conf.d/rabbitmq.json
	echo '{
		"client": {
		"name": "'$hostname'",
		"address": "'$address'",
		"environment": "prod",
		"keepalive": {
		"refresh": 90,
		"thresholds": {
		"critical": 300,
		"warning": 250
		},
		"handler": "email"
		},
		"subscriptions": ["cpu", "disk", "memory"],
		"socket": {
		"bind": "127.0.0.1",
		"port": 3030
		}
		}
	}' > /etc/sensu/conf.d/client.json
	
	#EDIT THE RABBITMQ HOST WITH YOUR RABBITMQ HOST AND CREDENTIALS
	echo '{
		"rabbitmq":
		{	
		"host": "172.31.25.208",
		"port": 5672,
		"vhost": "/sensu",
		"user": "sensu",
		"password": "secret"
		}
		}'> /etc/sensu/conf.d/rabbitmq.json

	echo -e "\e[31m \t\t\t\t\t client.json & rabbitmq.json files Added..! - Done\n\n"
	#INSTALLING THE BASIC CHECKS
	echo -e "\e[32m \t\t ##############################---- Installing the Basic Checks ----################################\n\n"
	sleep 1
	sudo sensu-install -p cpu-checks
	sudo sensu-install -p disk-checks
	sudo sensu-install -p memory-checks
	sudo sensu-install -p load-checks
	sudo sensu-install -p process-checks
	sudo sensu-install -p network-checks
	sudo sensu-install -p vmstats

	#ADDING THE SENSU CLIENT TO CHKCONFIG ON LIST & RESTARTING
	sudo update-rc.d sensu-client defaults 3 5
	sudo service sensu-client restart
	if [[ $? -eq 0 ]]
                then
        echo -e "\e[31m\n\n\t\t\t\t\t Sensu Client successfully installed on - $hostname ...! -Done\n\n"
                else
        echo -e "\e[32m\n\n\t\t\t\t\t Sensu Client Installation Failed on - $hostname ...! - Retry \n\n"
                fi
	exit 0
	#########################################ENDS FOR UBUNTU##################################################

else
	echo -e "\e[32m \t\t\t\t System is running on RHEL Based Operating System...!\n\n"
	echo -e "\e[31m#####################################---- Installing sensu for RHEL Based System ----##################################"
	#ADDING THE SENSU REPOS FOR UBUNTU AND BEGIN INSTALLATION
	echo -e "\e[32m\n\n \t\t\t\t\t Adding Sensu Repo For RHEL Based Systems...! -Done \n\n"
	echo '[sensu]
name=sensu
baseurl=http://sensu.global.ssl.fastly.net/yum/$basearch/
gpgcheck=0
enabled=1' > /etc/yum.repos.d/sensu.repo
	yum install sensu -y
	
	#CREATING CONF's AND ADDING THE CONFIGURATIONS
	#Edit the subsriptions and handlers as per how is configured in the server
	echo -e "\e[32m\n\n \t\t\t\t Adding the client.json & rabbitmq.json files with their configurations...! - Done \n\n"
	sleep 1
	sudo touch /etc/sensu/conf.d/client.json && sudo touch /etc/sensu/conf.d/rabbitmq.json
	echo '{
		"client": {
		"name": "'$hostname'",
		"address": "'$address'",
		"environment": "prod",
		"keepalive": {
		"refresh": 90,
		"thresholds": {
		"critical": 300,
		"warning": 250
		},
		"handler": "email"
		},
		"subscriptions": ["cpu", "disk", "memory"],
		"socket": {
		"bind": "127.0.0.1",
		"port": 3030
		}
		}
	}' > /etc/sensu/conf.d/client.json
	
	#EDIT THE RABBITMQ HOST WITH YOUR RABBITMQ HOST AND CREDENTIALS
	echo '{
		"rabbitmq":
		{	
		"host": "172.31.25.208",
		"port": 5672,
		"vhost": "/sensu",
		"user": "sensu",
		"password": "secret"
		}
		}'> /etc/sensu/conf.d/rabbitmq.json

	echo -e "\e[31m \t\t\t\t\t client.json & rabbitmq.json files Added..! - Done\n\n"
	#INSTALLING THE BASIC CHECKS
	echo -e "\e[32m \t\t ##############################---- Installing the Basic Checks ----################################\n\n"
	sleep 1
	sleep 1
	sudo sensu-install -p cpu-checks
	sudo sensu-install -p disk-checks
	sudo sensu-install -p memory-checks
	sudo sensu-install -p load-checks
	sudo sensu-install -p process-checks
	sudo sensu-install -p network-checks
	sudo sensu-install -p vmstats

	#ADDING THE SENSU CLIENT TO CHKCONFIG ON LIST & RESTARTING
	sudo chkconfig sensu-client on
	sudo service sensu-client restart
	if [[ $? -eq 0 ]]
		then
	echo -e "\e[31m\n\n\t\t\t\t\t Sensu Client successfully installed on - $hostname ...! -Done\n\n"
	#########################################ENDS FOR RHEL###################################################
		else	
	echo -e "\e[32m\n\n\t\t\t\t\t Sensu Client Installation Failed on - $hostname ...! - Retry \n\n"
		fi
	exit 0
fi

#Proactive (: Monitoring...!
