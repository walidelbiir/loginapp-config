#!/bin/bash

set -e


if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <kustomize-directory>"
  exit 1
fi


KUSTOMIZE_DIR=$1


NAMESPACE=$(yq eval '.namespace' $KUSTOMIZE_DIR/kustomization.yaml)


if [ -z "$NAMESPACE" ]; then
  echo "Namespace not found in kustomization.yaml"
  exit 1
fi


if kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
  echo "Namespace $NAMESPACE already exists."
else
  echo "Namespace $NAMESPACE does not exist. Creating..."
  kubectl create project $NAMESPACE
fi

oc create clusterrolebinding default-image-puller-$NAMESPACE --clusterrole=system:image-puller --serviceaccount=$NAMESPACE:default

oc apply -k $KUSTOMIZE_DIR

