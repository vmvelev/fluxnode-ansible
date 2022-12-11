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

function config_file() {
	if [[ -f /home/$USER/install_conf.json ]]; then
		import_settings=$(cat /home/$USER/install_conf.json | jq -r '.import_settings')
		bootstrap_url=$(cat /home/$USER/install_conf.json | jq -r '.bootstrap_url')
		bootstrap_zip_del=$(cat /home/$USER/install_conf.json | jq -r '.bootstrap_zip_del')
		use_old_chain=$(cat /home/$USER/install_conf.json | jq -r '.use_old_chain')
		prvkey=$(cat /home/$USER/install_conf.json | jq -r '.prvkey')
		outpoint=$(cat /home/$USER/install_conf.json | jq -r '.outpoint')
		index=$(cat /home/$USER/install_conf.json | jq -r '.index')
		zel_id=$(cat /home/$USER/install_conf.json | jq -r '.zelid')
		kda_address=$(cat /home/$USER/install_conf.json | jq -r '.kda_address')
		upnp_port=$(cat /home/$USER/install_conf.json | jq -r '.upnp_port')
    		gateway_ip=$(cat /home/$USER/install_conf.json | jq -r '.gateway_ip')
		echo -e "${ARROW} ${YELLOW}Install config summary:"
		if [[ "$prvkey" != "" && "$outpoint" != "" && "$index" != "" ]];then
			echo -e "${PIN}${CYAN}Import settings from install_conf.json...........................[${CHECK_MARK}${CYAN}]${NC}"
		else
			if [[ "$import_settings" == "1" ]]; then
				echo -e "${PIN}${CYAN}Import settings from exist config files..........................[${CHECK_MARK}${CYAN}]${NC}"
			fi
		fi

		if [[ "$use_old_chain" == "1" ]]; then
			echo -e "${PIN}${CYAN}During re-installation old chain will be used....................[${CHECK_MARK}${CYAN}]${NC}"
		else
			if [[ "$bootstrap_url" == "" || "$bootstrap_url" == "0" ]]; then
				echo -e "${PIN}${CYAN}Use Flux Bootstrap from source build in scripts..................[${CHECK_MARK}${CYAN}]${NC}"
			else
				echo -e "${PIN}${CYAN}Use Flux Bootstrap from own source...............................[${CHECK_MARK}${CYAN}]${NC}"
			fi
			if [[ "$bootstrap_zip_del" == "1" ]]; then
				echo -e "${PIN}${CYAN}Remove Flux Bootstrap archive file...............................[${CHECK_MARK}${CYAN}]${NC}"
			else
				echo -e "${PIN}${CYAN}Leave Flux Bootstrap archive file................................[${CHECK_MARK}${CYAN}]${NC}"
			fi
		fi

		if [[ ( "$discord" != "" && "$discord" != "0" ) || "$telegram_alert" == '1' ]]; then
			echo -e "${PIN}${CYAN}Enable watchdog notification.....................................[${CHECK_MARK}${CYAN}]${NC}"
		else
			echo -e "${PIN}${CYAN}Disable watchdog notification....................................[${CHECK_MARK}${CYAN}]${NC}"
		fi

		if [[ ! -z $gateway_ip && ! -z $upnp_port ]]; then
			echo -e "${PIN}${CYAN}Enable UPnP configuration........................................[${CHECK_MARK}${CYAN}]${NC}" 
		fi
	fi
}

if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
	echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
	echo -e "${CYAN}Please switch to the user account.${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	echo -e "${NC}"
	exit
fi
echo -e "${GREEN}Module: Create FluxNode installation config file${NC}"
echo -e "${YELLOW}================================================================${NC}"
if jq --version > /dev/null 2>&1; then
	sleep 0.2
else
	echo -e "${ARROW} ${YELLOW}Installing JQ....${NC}"
	sudo apt  install jq -y > /dev/null 2>&1
	if jq --version > /dev/null 2>&1; then
		#echo -e "${ARROW} ${CYAN}Nodejs version: ${GREEN}$(node -v)${CYAN} installed${NC}"
		string_limit_check_mark "JQ $(jq --version) installed................................." "JQ ${GREEN}$(jq --version)${CYAN} installed................................."
		echo
	else
		#echo -e "${ARROW} ${CYAN}Nodejs was not installed${NC}"
		string_limit_x_mark "JQ was not installed................................."
		echo
		exit
	fi
fi
skip_zelcash_config='0'
skip_bootstrap='0'
if [[ -d /home/$USER/$CONFIG_DIR ]]; then
	import_settings='0'
	use_old_chain='0'
fi

if [[ "$skip_zelcash_config" == "1" ]]; then
	prvkey=""
	outpoint=""
	index=""
	zelid=""
	kda_address=""
	node_label="0" 
	fix_action="1"      
	eps_limit="0"
	discord="0"
	ping="0"
	telegram_alert="0"    
	telegram_bot_token="0"	      	      
	telegram_chat_id="0"	
else
	read -p "Enter your FluxNode Identity Key from Zelcore: " prvkey
	read -p "Enter your FluxNode Collateral TX ID from Zelcore: " outpoint
	read -p "Enter your FluxNode Output Index from Zelcore: " index
	while true
	do
		read -p "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)): " zel_id
		if [ $(printf "%s" "$zel_id" | wc -c) -eq "34" ] || [ $(printf "%s" "$zel_id" | wc -c) -eq "33" ]; then
			echo -e "${ARROW} ${CYAN}Zel ID is valid${CYAN}.........................[${CHECK_MARK}${CYAN}]${NC}"
			break
		else
			echo -e "${ARROW} ${CYAN}Zel ID is not valid try again...........[${X_MARK}${CYAN}]${NC}"
			sleep 4
		fi
	done
	sleep 1
	while true
	do
		read -p "Please enter your Kadena address from Zelcore: " KDA_A
		KDA_A=$(grep -Eo "^k:[0-9a-z]{64}\b" <<< "$KDA_A")
		if [[ "$KDA_A" != "" && "$KDA_A" != *kadena* && "$KDA_A" = *k:*  ]]; then    
			echo -e "${ARROW} ${CYAN}Kadena address is valid.................[${CHECK_MARK}${CYAN}]${NC}"	
			kda_address="kadena:$KDA_A?chainid=0"		    
			sleep 2
			break
		else	     
			echo -e "${ARROW} ${CYAN}Kadena address is not valid.............[${X_MARK}${CYAN}]${NC}"
			sleep 2		     
		fi
	done
	sleep 1
	zelflux_update='1'
	zelcash_update='1'
	zelbench_update='1'
	discord="0"
	ping="0"
	telegram_alert="0"
	telegram_bot_token="0"
	telegram_chat_id="0"
	node_label="0"
	sleep 1

	if [[ "$discord" == 0 ]]; then
		ping="0"
	fi

	if [[ "$telegram_alert" == 0 || "$telegram_alert" == "" ]]; then
		telegram_alert="0"
		telegram_bot_token="0"
		telegram_chat_id="0"
	fi

	index_from_file="$index"
	tx_from_file="$outpoint"
	stak_info=$(curl -sSL -m 5 https://$network_url_1/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
	if [[ "$stak_info" == "" ]]; then
		stak_info=$(curl -sSL -m 5 https://$network_url_2/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
	fi	
	if [[ $stak_info == ?(-)+([0-9]) ]]; then
		case $stak_info in
		"1000") eps_limit=90 ;;
		"12500")  eps_limit=180 ;;
		"40000") eps_limit=300 ;;
		esac
	else
		eps_limit=0;
	fi
fi
if [[ "$skip_bootstrap" == "0" ]]; then
	bootstrap_url=""
	sleep 1
	bootstrap_zip_del='0'
	sleep 1
fi
read -p "Enter your UPnP Gateway IP: " gateway_ip
read -p "Enter your FluxOS UPnP Port: " upnp_port
firewall_disable='1'
swapon='1'
rm /home/$USER/install_conf.json > /dev/null 2>&1
install_conf_create
config_file
echo -e
