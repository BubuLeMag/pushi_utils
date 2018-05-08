#!/bin/bash

# Copyright (c) 2018 BubuLeMag
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

CONFIG_FILE='pushi.conf'
CONFIG_FOLDER=${HOME}'/.pushicore/'
COIN_DAEMON='pushid'
COIN_CLI='pushi-cli'
COIN_PATH=${HOME}'/pushi/src/'
COIN_GITHUB_REPO='pushiplay/pushi'
COIN_NAME='PUSHI'
COIN_COLLATERAL='10,000'
COIN_PORT=9847
RPC_PORT=9846

MANDATORY_UPDATE_VERSION='v1.0 v1.0.1 v1.1.0 v1.1.5 v1.1.6' # Put every version that need to be updated

BLOCKCHAIN_BLOCK_TEST=47720
BLOCKCHAIN_BLOCK_HASH="000000000000976ddf09325ca881fb65c150adda2f290c0f0f4f7f7b9a906456"

MAX=10

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NONE='\033[0m'



function check_file_location() {
	echo -e "${NONE}[1/${MAX}] Checking if ${COIN_CLI}, ${COIN_DAEMON} and ${CONFIG_FILE} exist.${NONE}";
	if [ -f $COIN_PATH$COIN_CLI ]; then
		echo -e "${GREEN} * Ok, ${COIN_CLI} exists.${NONE}"
	else
		echo -e "${RED}**** ${COIN_CLI} can't be found."
		echo -e "${RED}**** Please check the guide to download the binaries (Step 6.3 of the guide) and start this script again.${NONE}"
		exit 1
	fi
	if [ -f $COIN_PATH$COIN_DAEMON ]; then
		echo -e "${GREEN} * Ok, ${COIN_DAEMON} exists.${NONE}"
	else
		echo -e "${RED}**** ${COIN_DAEMON} can't be found."
		echo -e "${RED}**** Please check the guide to download the binaries (Step 6.3 of the guide) and start this script again.${NONE}"
		exit 1
	fi
	if [ -f $CONFIG_FOLDER$CONFIG_FILE ]; then
		echo -e "${GREEN} * Ok, ${CONFIG_FILE} exists.${NONE}"
	else
		echo -e "${RED}**** ${CONFIG_FILE} can't be found."
		echo -e "${RED}**** Please check the guide to create a pushi.conf in ${CONFIG_FOLDER} and start this script again.${NONE}"
		exit 1
	fi
}

function check_conf_file() {
	echo -e "${NONE}[2/${MAX}] Checking if masternode is enabled in the config file.${NONE}";
	MASTERNODE_ENABLED=$(grep -m 1 'masternode=1' $CONFIG_FOLDER$CONFIG_FILE 2> /dev/null)
	if [ $MASTERNODE_ENABLED ]; then
		echo -e "${GREEN} * Ok, you have masternode=1 in the config file.${NONE}"
	else
		echo -e "${RED}**** You don't have masternode=1 in the config file."
		echo -e "**** Please check your config file (Step 7 of the guide), restart $COIN_DAEMON and start this script again.${NONE}"
		exit 1
	fi 
}

function check_daemon_running() {
	echo -e "${NONE}[3/${MAX}] Checking if ${COIN_DAEMON} is running.${NONE}";
	DAEMON_RUNNING=$(ps axo cmd:100 | grep -m1 $COIN_PATH$COIN_DAEMON)
	if [ -n "$DAEMON_RUNNING" ]; then
		echo -e "${GREEN} * Ok, ${COIN_DAEMON} is running.${NONE}"
	else
		echo -e "${RED}**** ${COIN_DAEMON} is not running."
		echo -e "${RED}**** Please launch it with ${COIN_PATH}${COIN_DAEMON} and start this script again.${NONE}"
		exit 1
	fi
}

function check_files_version() {
	echo -e "${NONE}[4/${MAX}] Checking if ${COIN_CLI} and ${COIN_DAEMON} have the last version.${NONE}";
	COIN_CLI_VERSION=$($COIN_PATH$COIN_CLI --version | sed 's/^.*version \(v[0-9]\.[0-9]\.[0-9]\).*$/\1/')
	COIN_DAEMON_VERSION=$($COIN_PATH$COIN_DAEMON --version | grep -m 1 version | sed 's/^.*version \(v[0-9]\.[0-9]\.[0-9]\).*$/\1/')
	COIN_LATEST_VERSION=$( curl -s https://api.github.com/repos/${COIN_GITHUB_REPO}/releases/latest | grep tag_name | sed 's/^.*"tag_name": "\(v[0-9]\.[0-9]\.[0-9]\)",.*$/\1/')
	echo -e "${NONE} * CLI version : ${COIN_CLI_VERSION}"
	echo -e "${NONE} * DAEMON version : ${COIN_DAEMON_VERSION}"
	echo -e "${NONE} * GITHUB version : ${COIN_LATEST_VERSION}"
	if [ $COIN_CLI_VERSION != $COIN_DAEMON_VERSION ]; then
		echo -e "${RED}**** ${COIN_CLI} and ${COIN_DAEMON} don't have the same version. That is not good."
		echo -e "**** Please install the right binaries (Step 6.3 of the guide) and start this script again.${NONE}"
		exit 1
	fi
	if echo $MANDATORY_UPDATE_VERSION | grep -w $COIN_CLI_VERSION > /dev/null; then
		echo -e "${RED} **** You have a version that need to be updated (mandatory update).${NONE}."
		echo -e "${RED} **** Please check the UPGRADING section of the guide and start this script again.${NONE}"
		exit 1
	fi
	if [ $COIN_LATEST_VERSION = $COIN_CLI_VERSION ]; then
		echo -e "${GREEN} * Ok, you have the latest version of ${COIN_CLI} and ${COIN_DAEMON}.${NONE}"
	else
		echo -e "${YELLOW} * You don't have the latest version of ${COIN_CLI} and ${COIN_DAEMON}.${NONE}."
		echo -e "${YELLOW} * That might be ok if it's not a mandatory update... but you should update.${NONE}"
	fi
}

function check_mnsync() {
	echo -e "${NONE}[5/${MAX}] Waiting for sync, it may take some time...${NONE}";
	until $COIN_PATH$COIN_CLI mnsync status | grep -m 1 '"IsBlockchainSynced": true'; do sleep 1 ; done > /dev/null 2>&1
	echo -e "${GREEN} * Blockchain Synced${NONE}";
	until $COIN_PATH$COIN_CLI mnsync status | grep -m 1 '"IsMasternodeListSynced": true'; do sleep 1 ; done > /dev/null 2>&1
	echo -e "${GREEN} * Masternode List Synced${NONE}";
	until $COIN_PATH$COIN_CLI mnsync status | grep -m 1 '"IsWinnersListSynced": true'; do sleep 1 ; done > /dev/null 2>&1
	echo -e "${GREEN} * Winners List Synced${NONE}";
	until $COIN_PATH$COIN_CLI mnsync status | grep -m 1 '"IsSynced": true'; do sleep 1 ; done > /dev/null 2>&1
	echo -e "${GREEN} * Done sync.${NONE}";
}

function check_blockchain() {
	echo -e "${NONE}[6/${MAX}] Checking if you're on the right blockchain...${NONE}";
	HASH=$($COIN_PATH$COIN_CLI getblockhash $BLOCKCHAIN_BLOCK_TEST)
	if [ $HASH = $BLOCKCHAIN_BLOCK_HASH ]; then
		echo -e "${GREEN} * Ok, you're on the right blockchain.${NONE}"
	else
		echo -e "${RED}**** You're NOT on the right blockchain. Use this command to wipe the data and download everything again : ${COIN_CLI} mnsync reset"
		echo -e "**** Then restart this script.${NONE}"
		exit 1
	fi
	
}

function check_sentinel() {
	echo -e "${NONE}[7/${MAX}] Checking if sentinel is present...${NONE}";
	if [ -f $COIN_PATH/sentinel/bin/sentinel.py ]; then
			echo -e "${GREEN} * Ok, sentinel is present.${NONE}"
		else
			echo -e "${RED}**** sentinel can't be found."
			echo -e "${RED}**** Please check the guide to install sentinel (Step 9) and start this script again.${NONE}"
			exit 1
		fi
}

function check_crontab() {
	echo -e "${NONE}[8/${MAX}] Checking if sentinel is in crontab...${NONE}";
	CRONTAB=$(crontab -l | grep -m1 "* * * * * cd ${HOME}/pushi/src/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" | grep -v '^#')
	if [ -n "$CRONTAB" ]; then
		echo -e "${GREEN} * Ok, sentinel is in crontab.${NONE}"
	else
		echo -e "${RED}**** Sentinel is not in the crontab."
		echo -e "${RED}**** Please check the guide to install sentinel (Step 9) and start this script again.${NONE}"
		exit 1
	fi
}

function check_masternode_in_list() {
	echo -e "${NONE}[9/${MAX}] Checking if your masternode is in the list...${NONE}";
	IP_ADDRESS=$(ip route get 1 | awk '{print $NF;exit}')
	MASTERNODE_FOUND=""
	WAITING_MASTERNODE_TIME=0
	MASTERNODE_FOUND=$($COIN_PATH$COIN_CLI masternode list info ${IP_ADDRESS} | grep -v '{' | grep -v '}')
	until [ -n "$MASTERNODE_FOUND" ]; do 
		if [ "$WAITING_MASTERNODE_TIME" -ne "60" ]; then
			echo -ne "\r${YELLOW} * Waiting for the masternode in the masternode list... ${WAITING_MASTERNODE_TIME}${NONE}"
		else 
			echo -e "\r${YELLOW}Still not found. Check the debug.log of your DESKTOP wallet.${NONE}"
			echo -e "${YELLOW}You should find lines like this 'DSEG -- Sent 1 Masternode inv to peer' neer the time you tried to start the MN.${NONE}"
			echo -e "${YELLOW}If you don't find these lines, start the MN again (End of step 8 of the guide). Otherwise, please wait a little longer...${NONE}"
			echo -e "${YELLOW}To quit this script, you can do CTRL-C.${NONE}"
			echo -ne "\r${YELLOW} * Waiting for the masternode in the masternode list... ${WAITING_MASTERNODE_TIME}${NONE}"
		fi
		((WAITING_MASTERNODE_TIME++))
		sleep 1
		MASTERNODE_FOUND=$($COIN_PATH$COIN_CLI masternode list info ${IP_ADDRESS} | grep -v '{' | grep -v '}')
	done 
	echo -e "\r${GREEN} * Ok, the masternode IP is in the masternode list."
}

function check_masternode_status() {
	echo -e "${NONE}[10/${MAX}] Checking masternode status...${NONE}";
	MASTERNODE_STATUS=$($COIN_PATH$COIN_CLI masternode status | grep 'Masternode successfully started')
	if [ -n "$MASTERNODE_STATUS" ]; then
		echo -e "${GREEN} * Congratulation : your masternode is started"
	else
		echo -e "${RED} * There is a problem. This script should have deal with that before. Please contact us on discord."
		echo -e "${RED} * Explain that you used this script and that the step 10 said that the status is : "$($COIN_PATH$COIN_CLI masternode status | grep 'status') 
	fi
}

check_file_location
check_conf_file
check_daemon_running
check_files_version
check_mnsync
check_blockchain
check_sentinel
check_crontab
echo -e "${NONE}Ok, everything is set according to the guide.${NONE}";
echo -e "${NONE}If you have at least 15 confirmations on the ${COIN_COLLATERAL} ${COIN_NAME} transaction you may start your MN (End of step 8 of the guide).${NONE}";
echo -e "${NONE}If you did that already, please wait...${NONE}"
check_masternode_in_list
check_masternode_status
echo -e "${NONE}Now your masternode might be in WATCHDOG_EXPIRED in your desktop wallet. Wait for at least one hour before worrying about that.${NONE}"
echo -e "${NONE}If after one hour, it's still WATCHDOG_EPIRED, check the Sentinel debugging step of the guide and contact us on discord.${NONE}"
tput sgr0
