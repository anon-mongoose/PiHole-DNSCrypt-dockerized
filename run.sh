#!/bin/bash


echo -e "\n     P I H O L E   -   D N S C R Y P T    P R O X Y   w i t h   D o c k e r\n"


dnscrypt_dockerfile_path="./dnscrypt/Dockerfile"
docker_compose_file_path="./docker-compose.yaml"


#=================================================================
# Step 1: Getting PiHole and DNSCrypt last versions
#=================================================================

pihole_version=$(curl -s https://github.com/pi-hole/docker-pi-hole/releases/latest | grep -o "\([0-9][0-9]\|[0-9]\).\([0-9][0-9]\|[0-9]\)\(.\([0-9][0-9]\|[0-9]\)\)\{0,1\}")
dnscrypt_version=$(curl -s https://github.com/DNSCrypt/dnscrypt-proxy/releases/latest | grep -o "\([0-9][0-9]\|[0-9]\).\([0-9][0-9]\|[0-9]\)\(.\([0-9][0-9]\|[0-9]\)\)\{0,1\}")

echo "PiHole latest version:          $pihole_version"
echo -e "DNSCrypt Proxy latest version:  $dnscrypt_version\n"



#=================================================================
# Step 2: Checking current containers versions
#=================================================================

# 2.1) Test if PiHole is up to date

pihole_uptodate=1
if [ $(docker images | grep 'pihole/pihole' | grep -o "$pihole_version") ]
then
	echo "The latest version of PiHole Docker container is up to date.           Nothing to do."
	pihole_uptodate=0
else
	echo "The latest version of Pihole should be installed."
fi



# 2.2) Test if DNSCrypt is up to date

dnscrypt_uptodate=1
if [ $(docker images | grep 'dnscrypt-custom' | grep -o "$dnscrypt_version") ]
then
	echo "The latest version of DNSCrypt Proxy Docker container is up to date.   Nothing to do."
	dnscrypt_uptodate=0
else
	echo "The latest version of DNSCrypt Proxy should be installed."
fi



#=================================================================
# Step 3: Updating docker-compose file and DNSCrypt Dockerfile
#=================================================================

if [ "$pihole_uptodate" -eq 1 ]
then
	echo -e "\n----------------------------------------------------------------------------"
	echo -e "\nThe last version availabled for PiHole Docker conatainer is $pihole_version\n"
	echo "The PiHole Docker container(s) currently installed is/are the following:"
	docker images | grep 'pihole/pihole'

	echo -e "\nDo you want to update it ?"
	echo -n "y|n > "
	read choice
	case $choice in
		[yYoO]*) echo -e "\n-> Updating PiHole Docker container..."
			 sed -i "18c\ \ \ \ image: pihole/pihole:v$pihole_version" $docker_compose_file_path
			 echo "-> Updated !";;
		[nN]*) echo "Do not hesitate to edit the docker-compose file with the version you want.";;
		*) echo "-> Choice incorrect. Exiting."
		   exit 1;;
	esac
fi



if [ "$dnscrypt_uptodate" -eq 1 ]
then
	echo -e "\n----------------------------------------------------------------------------"
	echo -e "\nThe last version availabled for DNSCrypt Proxy is $dnscrypt_version\n"
	echo "The DNScrypt Proxy Docker containers currently installed is/are the following:"
	docker images | grep 'dnscrypt-custom'

	echo -e "\nDo you want to update it ?"
	echo -n "y|n > "
	read choice
	case $choice in
		[yYoO]*) echo -e "\n-> Updating DNSCrypt Proxy Docker container..."
			 sed -i "7c\ \ \ \ image: dnscrypt-custom:v$dnscrypt_version" $docker_compose_file_path
			 sed -i "9cRUN wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/$dnscrypt_version/dnscrypt-proxy-linux_x86_64-$dnscrypt_version.tar.gz" $dnscrypt_dockerfile_path
			 sed -i "10cRUN tar xvzf dnscrypt-proxy-linux_x86_64-$dnscrypt_version.tar.gz" $dnscrypt_dockerfile_path
			 echo "-> Updated !";;
		[nN]*) echo "Do not hesitate to edit the DNSCrypt Dockerfile file with the version you want.";;
		*) echo "-> Choice incorrect. Exiting."
		   exit 1;;
	esac
fi


#=================================================================
# Step 4: Redploying updated containers
#=================================================================

if [ "$pihole_uptodate" -eq 1 -o "$dnscrypt_uptodate" -eq 1  ]
then
	echo -e "\n----------------------------------------------------------------------------"
	echo -e "\-> Redeploying updated containers....\n"
	docker-compose -f $docker_compose_file_path down
	docker-compose -f $docker_compose_file_path up
	echo -e "\n-> Containers updated !"
fi

exit 0