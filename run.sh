#!/bin/bash


echo -e "\n     P I H O L E   -   D N S C R Y P T    P R O X Y   w i t h   D o c k e r\n"


dnscrypt_dockerfile_path="./dnscrypt/Dockerfile"
docker_compose_file_path="./docker-compose.yaml"
arch="x86_64" # x86_64, arm,arm64, i386...


#=================================================================
# Step 0: Check script arguments
#=================================================================

if [ "$#" -eq 0 ]; then
	force_update="false"
elif [ "$#" -eq 1 ]; then
	if [ "$1" = "-f" -o "$1" = "--force" ]; then
		force_update="true"

	elif [ "$1" = "-u" -o "$1" = "--up" ]; then
		docker compose -f ${docker_compose_file_path} up -d

	elif [ "$1" = "-d" -o "$1" = "--down" ]; then
		docker compose -f ${docker_compose_file_path} down

	elif [ "$1" = "-h" -o "$1" = "--help" ]; then
		echo "This script will install/update the PiHole and DNSCrypt proxy docker containers to the latest version automatically."
		echo "Options list:"
		echo "  -h, --help     Print this help message."
		echo "  -f, --force    Update compose file if any update is available"
		echo "  -u, --up       Docker Compose UP"
		echo "  -d, --down     Docker Compose DOWN"
		echo -e "\nYou can copy, modify and distribute this scrip as you wish, but do not forget to link this GitHub repository.\n"
		exit 0

	else
		echo "Error: bad arguments."
		echo -e "To print the help message, use  $0 -h\n"
		exit 1
  fi

else
	echo "Error: bad arguments."
	echo -e "To print the help message, use  $0 -h\n"
	exit 1
fi


#=================================================================
# Step 1: Getting PiHole and DNSCrypt last versions
#=================================================================

pihole_version=$(echo $(curl -Ls -o /dev/null -w %{url_effective} https://github.com/pi-hole/docker-pi-hole/releases/latest) | cut -d'/' -f8)

dnscrypt_version="none"
version_found=0
for version in $(curl -s https://github.com/DNSCrypt/dnscrypt-proxy/releases/ | grep '/DNSCrypt/dnscrypt-proxy/tree/' | cut -d"\"" -f2 | cut -d"/" -f5)
do
  if [ "$(echo $version | grep -c -m 1 '-')" == "0" -a ${version_found} -eq 0 ]; then
    dnscrypt_version=${version}
    version_found=1
  fi
done

echo "PiHole latest version:                ${pihole_version}"
echo "DNSCrypt Proxy latest version:        ${dnscrypt_version}"
echo "DNSCrypt Proxy architecture defined:  ${arch}"
echo -e "(Note: Make sure this architecture works on the host machine. Otherwise, update the 'arch' variable at the top of ${0})\n"


#=================================================================
# Step 2: Checking current containers versions
#=================================================================

# 2.1) Test if PiHole is up to date

pihole_uptodate=1
if [ $(docker image ls | grep 'pihole/pihole' | grep -o "${pihole_version}") ]
then
	echo "The latest version of PiHole Docker image is up to date. Nothing to do!"
	pihole_uptodate=0
else
	echo "The latest version of Pihole should be installed."
fi



# 2.2) Test if DNSCrypt is up to date

dnscrypt_uptodate=1
if [ $(docker image ls | grep 'dnscrypt-custom' | grep -o "${dnscrypt_version}") ]
then
	echo "The latest version of DNSCrypt Proxy Docker image is up to date. Nothing to do!"
	dnscrypt_uptodate=0
else
	echo "The latest version of DNSCrypt Proxy should be installed."
fi



#=================================================================
# Step 3: Updating docker-compose file and DNSCrypt Dockerfile
#=================================================================

if [ "${pihole_uptodate}" -eq 1 -a "${force_update}" = "false" ]
then
	echo -e "\n----------------------------------------------------------------------------"
	echo -e "\nThe last version availabled for PiHole Docker container is ${pihole_version}\n"
	echo "The PiHole Docker container(s) currently installed is/are the following:"
	CONTENT="$(docker image ls | grep 'pihole/pihole')"
	if [ "$CONTENT" == "" ]; then echo "(nothing)"; else echo "$CONTENT"; fi

	echo -e "\nDo you want to update it in docker-compose file?"
	echo -n "y|n > "
	read choice
	case ${choice} in
		[yYoO]*) echo -e "\n-> Updating PiHole Docker container..."
			 sed -i "18c\ \ \ \ image: pihole/pihole:${pihole_version}" ${docker_compose_file_path}
			 echo "-> Updated !";;
		[nN]*) echo "Do not hesitate to edit the docker-compose file with the version you want.";;
		*) echo "-> Choice incorrect. Exiting."
		   exit 1;;
	esac
fi



if [ "${dnscrypt_uptodate}" -eq 1 -a "${force_update}" = "false" ]
then
	echo -e "\n----------------------------------------------------------------------------"
	echo -e "\nThe last version availabled for DNSCrypt Proxy is ${dnscrypt_version}\n"
	echo "The DNScrypt Proxy Docker containers currently installed is/are the following:"
	CONTENT="$(docker image ls | grep 'dnscrypt-custom')"
	if [ "$CONTENT" == "" ]; then echo "(nothing)"; else echo "$CONTENT"; fi

	echo -e "\nDo you want to update it in docker-compose file?"
	echo -n "y|n > "
	read choice
	case ${choice} in
		[yYoO]*) echo -e "\n-> Updating DNSCrypt Proxy Docker container..."
			 sed -i "4c\ \ \ \ image: dnscrypt-custom:v${dnscrypt_version}" ${docker_compose_file_path}
			 sed -i "14cRUN wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/${dnscrypt_version}/dnscrypt-proxy-linux_${arch}-${dnscrypt_version}.tar.gz" ${dnscrypt_dockerfile_path}
			 sed -i "15cRUN tar xvzf dnscrypt-proxy-linux_${arch}-${dnscrypt_version}.tar.gz" ${dnscrypt_dockerfile_path}
			 sed -i "16cRUN mv linux-${arch}/ /usr/local/dnscrypt-proxy" ${dnscrypt_dockerfile_path}
			 echo "-> Updated !";;
		[nN]*) echo "Do not hesitate to edit the DNSCrypt Dockerfile file with the version you want.";;
		*) echo "-> Choice incorrect. Exiting."
		   exit 1;;
	esac
fi


#=================================================================
# Step 4: Redeploying updated containers
#=================================================================

if [ "${pihole_uptodate}" -eq 1 -o "${dnscrypt_uptodate}" -eq 1  ]
then
	echo -e "\nDo you want to (re)deploy the proxies?"
	echo -n "y|n > "
	read choice
	case ${choice} in
		[yYoO]*) echo -e "\n----------------------------------------------------------------------------"
				 echo -e "\n-> Redeploying updated containers....\n"
				 docker compose -f ${docker_compose_file_path} down
				 docker compose -f ${docker_compose_file_path} up -d # if you want to see log details, remove the '-d' option.
				 echo -e "\n-> Containers updated !";;
		[nN]*) echo -e "To deploy docker-compose file, run the following command:\n   docker compose -f ${docker_compose_file_path} up";;
		*) echo "-> Choice incorrect. Exiting."
		   exit 1;;
	esac
fi

exit 0
