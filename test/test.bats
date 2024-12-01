#!/usr/bin/env bats


# Define constants
CHART_FILE="Chart.yaml"
TEMP_CHART_FILE="Chart.temp.yaml"
CHART_PATH="example-chart"
REPOSITORY="example-chart-repo"
EXPECTED_VERSION="0.0.2"
EXPECTED_APP_VERSION="eb8b0d81"


# Setup a temporary directory for testing
setup() {
  # Create a fake repository and Chart.yaml
  TEST_REPO=$(mktemp -d)
  cp src/run.sh $TEST_REPO

  mkdir -p "$TEST_REPO/.ssh"

  touch $TEST_REPO/.ssh/id_rsa $TEST_REPO/.ssh/known_hosts

  mkdir -p "$TEST_REPO/$REPOSITORY"
  cd "$TEST_REPO/$REPOSITORY"

  git init
  git config user.email "test@example.com"
  git config user.name "Test User"
  git config commit.gpgsign false

  mkdir -p $CHART_PATH

  cat <<EOF > $CHART_PATH/Chart.yaml
apiVersion: v2
name: example-chart
description: Helm Chart Description
type: application
version: 0.0.1
appVersion: "a1b2c3d4"
EOF

  git add $CHART_PATH/Chart.yaml
  git commit -m "Initial commit"
  cd $TEST_REPO
}

# Teardown: Clean up the fake repository after testing
teardown() {
  cd ..
  rm -rf "$TEST_REPO"
}

@test "run.sh updates Chart.yaml with new appVersion and version" {

  # Export necessary environment variables
  export PLUGIN_TEST=true
  export PLUGIN_SSH_FOLDER="$TEST_REPO/.ssh"
  export PLUGIN_SSH_PRIVATE_KEY_FILE="$TEST_REPO/.ssh/id_rsa"
  export PLUGIN_KNOWN_HOSTS_FILE="$TEST_REPO/.ssh/known_hosts"
  export PLUGIN_SSH_URL="git@fakeaddress.com:user/$REPOSITORY"
  export PLUGIN_SSH_KEY="fake-key"
  export PLUGIN_EMAIL="test@example.com"
  export PLUGIN_NAME="Test User"
  export PLUGIN_IMAGE_TAG="$EXPECTED_APP_VERSION"
  export PLUGIN_CHART_PATH="$CHART_PATH"

  # Run the script
  run $TEST_REPO/run.sh

  # Check that the script ran successfully
  [ "$status" -eq 0 ]

  # Verify Chart.yaml was updated correctly
  run grep "version: $EXPECTED_VERSION" $REPOSITORY/$CHART_PATH/Chart.yaml
  [ "$status" -eq 0 ]

  run grep "appVersion: /"$EXPECTED_APP_VERSION"/" $REPOSITORY/$CHART_PATH/Chart.yaml
  [ "$status" -eq 0 ]

  # Verify git commit was made
  cd $TEST_REPO/$REPOSITORY
  run git log --oneline
  [ "$(grep -c "Update image version to $EXPECTED_APP_VERSION" <<<"$output")" -eq 1 ]
  cd -
}
