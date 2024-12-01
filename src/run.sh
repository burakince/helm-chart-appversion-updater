#!/bin/bash

set -e
set -o pipefail

function check_command {
  COMMAND_PARAMETER=$1

  if ! command -v ${COMMAND_PARAMETER} &> /dev/null
  then
    echo "Command '${COMMAND_PARAMETER}' could not be found. Please use 'brew install ${COMMAND_PARAMETER}'"
    exit
  fi
}

check_command jq
check_command curl
check_command git

DEBUG_MODE="${PLUGIN_DEBUG:-false}"
TEST_MODE="${PLUGIN_TEST:-false}"

URL="${PLUGIN_SSH_URL:?SSH URL empty or unset}"

SSH_KEY="${PLUGIN_SSH_KEY:?SSH Key empty or unset}"
SSH_FOLDER="${PLUGIN_SSH_FOLDER:-/root/.ssh}"
SSH_PRIVATE_KEY_FILE="${PLUGIN_SSH_PRIVATE_KEY_FILE:-$SSH_FOLDER/id_rsa}"
SSH_KNOWN_HOSTS_FILE="${PLUGIN_KNOWN_HOSTS_FILE:-$SSH_FOLDER/known_hosts}"

echo -n "$SSH_KEY" > $SSH_PRIVATE_KEY_FILE
chmod 600 $SSH_PRIVATE_KEY_FILE

if [ "$DEBUG_MODE" = true ] ; then
  cat $SSH_PRIVATE_KEY_FILE
  ls -al $SSH_FOLDER
fi

HOSTNAME=""
USER=""
REPOSITORY=""

REGEX="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+)(.git)*$"

if [[ $URL =~ $REGEX ]]; then
  protocol=${BASH_REMATCH[1]}
  separator=${BASH_REMATCH[2]}
  HOSTNAME=${BASH_REMATCH[3]}
  USER=${BASH_REMATCH[4]}
  REPOSITORY=${BASH_REMATCH[5]}
  REPOSITORY="${REPOSITORY%.git}"

  if [ "$DEBUG_MODE" = true ] ; then
    echo $protocol
    echo $separator
    echo $HOSTNAME
    echo $USER
    echo $REPOSITORY
  fi

  if [ "$protocol" != "git" ]; then
    echo "Doesn't supported protocol: $protocol"
    exit 1
  fi
else
  echo "SSH URL is invalid! URL is $URL"
  exit 1
fi

if [ "$TEST_MODE" = false ] ; then
  ssh-keyscan -t rsa $HOSTNAME >> $SSH_KNOWN_HOSTS_FILE
fi

if [ "$DEBUG_MODE" = true ] ; then
  cat $SSH_KNOWN_HOSTS_FILE
fi

IMAGE_TAG="${PLUGIN_IMAGE_TAG:?Image tag empty or unset}"
if [ "$TEST_MODE" = false ] ; then
  rm -rf $REPOSITORY
  git clone git@$HOSTNAME:$USER/$REPOSITORY.git
fi
cd $REPOSITORY

EMAIL="${PLUGIN_EMAIL:?User email empty or unset}"
git config user.email "$EMAIL"
NAME="${PLUGIN_NAME:?User name empty or unset}"
git config user.name "$NAME"

if [ "$DEBUG_MODE" = true ] ; then
  ls -al
fi

CURRENT_BRANCH=$(git branch --show-current)

CHART_PATH="${PLUGIN_CHART_PATH:?Chart folder path empty or unset}"
CHART_APP_VERSION=$(grep '^appVersion:' $CHART_PATH/Chart.yaml | awk '{print $2}')

if [ "$IMAGE_TAG" == "$CHART_APP_VERSION" ]; then
  echo "We have latest app version! Our synced app version: $CHART_APP_VERSION and new app version: $IMAGE_TAG"
  exit 0
fi

CHART_VERSION=$(grep '^version:' $CHART_PATH/Chart.yaml | awk '{print $2}')
CHART_VERSION_NEXT="${CHART_VERSION%.*}.$((${CHART_VERSION##*.}+1))"

sed -i'.bak' -e 's|^version:.*|version: '"$CHART_VERSION_NEXT"'|g' $CHART_PATH/Chart.yaml
sed -i'.bak' -e 's|^appVersion:.*|appVersion: '\""$IMAGE_TAG"\"'|g' $CHART_PATH/Chart.yaml

if [ "$DEBUG_MODE" = true ] ; then
  cat $CHART_PATH/Chart.yaml
fi

echo "Commiting chart source changes to $CURRENT_BRANCH branch"
git add $CHART_PATH/Chart.yaml
git commit --message "Update image version to $IMAGE_TAG"

if [ "$TEST_MODE" = false ] ; then
  git push --set-upstream origin $CURRENT_BRANCH
fi

cd -
