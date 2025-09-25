#!/usr/bin/env bash

# Author: alphajerboa

cat << EOF
Welcome to your workstation setup program
This script will install all usual tools on your workstation

This script requires root priviligies (sudo), so please enter your user password when prompted (sudo, become)

EOF


clean_exit(){

    # Remove temporary folder if needed
    [[ "$GIT_REPO_PATH" =~ ^/tmp/tmp* ]] && rm -Rf $GIT_REPO_PATH
    exit ${1:-0}
}

# Variables definition
GIT_REPO_NAME="workstation_setup"
GIT_REPO_BRANCH="main"
GIT_REPO_CREDS="<my_cred>"
GIT_REPO_URL="<my_repo_url"
TAGS=common,${1:-setup}

# Folder check/creation to store local copy of the git repository
#GIT_REPO_PATH=~/src/github # using a static defined folder
GIT_REPO_PATH=$(mktemp -d)  # Using a temporary folder (deleted at the end of the script)

trap clean_exit SIGINT SIGKILL SIGTERM

# Check network connectivity
! nc -w1 -z 1.1.1.1 53 &>/dev/null && echo "No internet connectivity, please check your network configuration (IP+DNS)" && clean_exit 1

# List of packages to install
APT_PACKAGES="ca-certificates \
curl \
software-properties-common \
git"

# Install basic package
sudo apt update && \
sudo apt install -y $APT_PACKAGES

# Install ansible
sudo add-apt-repository --yes --update ppa:ansible/ansible && \
sudo apt install -y ansible

# Check tools installation
for TOOL in git ansible-playbook
do
    ! command -v $TOOL &> /dev/null && echo "$TOOL is missing" && clean_exit 1
done

# Get ansible repository
if [[ -d $GIT_REPO_PATH/$GIT_REPO_NAME ]];
then
    # Folder already exist, check if it is a git repo and if it is the good repo
    cd $GIT_REPO_PATH/$GIT_REPO_NAME
    [[ ! -d .git ]] && echo "The current working directory isn't a git repository" && clean_exit 1
    ! git config -l | grep -q "^remote.origin.url=.*@${GIT_REPO_URL}$" && echo "The current working directory is not a copy of the github repository $GIT_REPO_NAME" && clean_exit 1
    # Reset local copy of the repository
    git fetch origin
    git checkout $GIT_REPO_BRANCH
    git reset --hard origin/$GIT_REPO_BRANCH
else
    # Not local copy of the git repository yet
    mkdir -p $GIT_REPO_PATH
    cd $GIT_REPO_PATH
    git clone --depth=1 --branch=$GIT_REPO_BRANCH https://${GIT_REPO_CREDS}@${GIT_REPO_URL} $GIT_REPO_NAME
    cd $GIT_REPO_NAME
fi


# Run ansible playbook on local host
ansible-playbook \
--connection=local \
--limit 127.0.0.1 \
--tags $TAGS \
--ask-become-pass \
main.yml

clean_exit 0




# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
