#!/bin/bash

set -e


if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <kustomize-directory>"
  exit 1
fi


KUSTOMIZE_DIR=$1


NAMESPACE=$(yq eval '.namespace' $KUSTOMIZE_DIR/kustomization.yaml)
PV_NAME=mysql-$(NAMESPACE:8)-pv


if [ -z "$NAMESPACE" ]; then
  echo "Namespace not found in kustomization.yaml"
  exit 1
fi


if kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
  echo "Namespace $NAMESPACE already exists."
else
  echo "Namespace $NAMESPACE does not exist. Creating..."
  kubectl create namespace $NAMESPACE
fi

CLUSTERROLEBINDING_NAME="default-image-puller-$NAMESPACE"

if ! oc get clusterrolebinding "$CLUSTERROLEBINDING_NAME" > /dev/null 2>&1; then
  echo "ClusterRoleBinding $CLUSTERROLEBINDING_NAME does not exist. Creating..."
  oc create clusterrolebinding "$CLUSTERROLEBINDING_NAME" --clusterrole=system:image-puller --serviceaccount=$NAMESPACE:default
else
  echo "ClusterRoleBinding $CLUSTERROLEBINDING_NAME already exists."
fi

oc apply -k $KUSTOMIZE_DIR

chmod 777 /mnt/data/nfs/$PV_NAME

