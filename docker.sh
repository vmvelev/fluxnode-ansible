#!/bin/bash
#disable bash history
set +o history

if ! [[ -z $1 ]]; then
	if [[ $BRANCH_ALREADY_REFERENCED != '1' ]]; then
	export ROOT_BRANCH="$1"
	export BRANCH_ALREADY_REFERENCED='1'
	bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/multitoolbox.sh) $ROOT_BRANCH
	unset ROOT_BRANCH
	unset BRANCH_ALREADY_REFERENCED
	set -o history
	exit
	fi
else
	export ROOT_BRANCH='master'
fi
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/flux_common.sh)"
if [[ -d /home/$USER/.zelcash ]]; then
	CONFIG_DIR='.zelcash'
	CONFIG_FILE='zelcash.conf'
else
	CONFIG_DIR='.flux'
	CONFIG_FILE='flux.conf'
fi

FLUX_DIR='zelflux'
FLUX_APPS_DIR='ZelApps'
COIN_NAME='zelcash'
dversion="v7.4"
PM2_INSTALL="0"
zelflux_setting_import="0"
echo -e "${GREEN}Module: Install Docker${NC}"
echo -e "${YELLOW}================================================================${NC}"
if [[ "$USER" != "root" ]]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the root account use command 'sudo su -'.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi
if [[ $(lsb_release -d) != *Debian* && $(lsb_release -d) != *Ubuntu* ]]; then
    echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version not supported${NC}"
    echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
    echo
    exit
fi
if [[ $(lsb_release -cs) == "jammy" ]]; then
    echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version not supported${NC}"
    echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
    echo
    exit
fi
read -p "Enter your username: " usernew
usernew=$(awk '{print tolower($0)}' <<< "$usernew")
echo -e "${ARROW} ${CYAN}New User: ${GREEN}${usernew}${NC}"
adduser --gecos "" "$usernew" 
usermod -aG sudo "$usernew" > /dev/null 2>&1  
echo -e "${ARROW} ${YELLOW}Update and upgrade system...${NC}"
apt update -y && apt upgrade -y 
if ! ufw version > /dev/null 2>&1; then
    echo -e "${ARROW} ${YELLOW}Installing ufw firewall..${NC}"
    sudo apt-get install -y ufw > /dev/null 2>&1
fi
cron_check=$(systemctl status cron 2> /dev/null | grep 'active' | wc -l)
if [[ "$cron_check" == "0" ]]; then
    echo -e "${ARROW} ${YELLOW}Installing crontab...${NC}"
    sudo apt-get install -y cron > /dev/null 2>&1
fi
echo -e "${ARROW} ${YELLOW}Installing docker...${NC}"
echo -e "${ARROW} ${CYAN}Architecture: ${GREEN}$(dpkg --print-architecture)${NC}"      
if [[ -f /usr/share/keyrings/docker-archive-keyring.gpg ]]; then
    sudo rm /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
fi
if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
    sudo rm /etc/apt/sources.list.d/docker.list > /dev/null 2>&1 
fi
if [[ $(lsb_release -d) = *Debian* ]]; then
    sudo apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1 
    sudo apt-get update -y  > /dev/null 2>&1
    sudo apt-get -y install apt-transport-https ca-certificates > /dev/null 2>&1 
    sudo apt-get -y install curl gnupg-agent software-properties-common > /dev/null 2>&1
    #curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - > /dev/null 2>&1
    #sudo add-apt-repository -y "deb [arch=amd64,arm64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /dev/null 2>&1
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1
    sudo apt-get update -y  > /dev/null 2>&1
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1  
else
    sudo apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1 
    sudo apt-get -y install apt-transport-https ca-certificates > /dev/null 2>&1  
    sudo apt-get -y install curl gnupg-agent software-properties-common > /dev/null 2>&1  
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1
    #curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null 2>&1
    #sudo add-apt-repository -y "deb [arch=amd64,arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /dev/null 2>&1
    sudo apt-get update -y  > /dev/null 2>&1
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1
fi
echo -e "${ARROW} ${YELLOW}Adding $usernew to docker group...${NC}"
adduser "$usernew" docker 
echo -e "${NC}"
echo -e "${YELLOW}=====================================================${NC}"
echo -e "${YELLOW}Running through some checks...${NC}"
echo -e "${YELLOW}=====================================================${NC}"
if sudo docker run hello-world > /dev/null 2>&1; then
    echo -e "${CHECK_MARK} ${CYAN}Docker is installed${NC}"
else
    echo -e "${X_MARK} ${CYAN}Docker did not installed${NC}"
fi
if [[ $(getent group docker | grep "$usernew") ]]; then
    echo -e "${CHECK_MARK} ${CYAN}User $usernew is member of 'docker'${NC}"
else
    echo -e "${X_MARK} ${CYAN}User $usernew is not member of 'docker'${NC}"
fi
echo -e "${YELLOW}=====================================================${NC}"
echo -e "${NC}"
read -p "Would you like switch to user account Y/N?" -n 1 -r
echo -e "${NC}"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    su - $usernew
fi
