#!/bin/bash

set -e

# Function to apply OC resources
apply_resources() {
    oc apply -f ./components/DockerBuildStrat/
}

# Function to start the build and get the build name
start_build() {
    build_name=$(oc start-build buildconfig-name -o name)
    echo ${build_name#build.build.openshift.io/}
}

# Function to check build status
check_build_status() {
    local build_name=$1
    oc get build ${build_name} -o jsonpath='{.status.phase}'
}

# Function to get image SHA
get_image_sha() {
    local build_name=$1
    oc get build ${build_name} -o jsonpath='{.status.outputDockerImageReference}'
}

# Main execution
apply_resources

build_name=$(start_build)

echo "Build started: ${build_name}"

while true; do
    status=$(check_build_status ${build_name})
    echo "Current build status: ${status}"

    if [ "$status" == "Complete" ]; then
        image_sha=$(get_image_sha ${build_name})
        echo "Build successful. Image SHA: ${image_sha}"
        exit 0
    elif [ "$status" == "Failed" ] || [ "$status" == "Cancelled" ] || [ "$status" == "Error" ]; then
        echo "An error occurred during the build process."
        exit 1
    fi

    sleep 10
done