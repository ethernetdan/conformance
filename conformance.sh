#!/bin/bash -x
set -euo pipefail

CONFORMANCE_REPO=${CONFORMANCE_REPO:-"github.com/kubernetes/kubernetes"}
CONFORMANCE_TAG=${CONFORMANCE_TAG:-"v1.6.4"}

IMAGE_NAME=${IMAGE_NAME:-"kube-conformance"}
IMAGE_TAG=${IMAGE_TAG:-"${CONFORMANCE_TAG}"}

echo "Building conformance image..."
echo

APT_PACKAGES="rsync"
# build docker image of repository
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" - <<EOF
    FROM golang:1.7.4
    # install conformance dependencies
    RUN apt-get update && apt-get install -y ${APT_PACKAGES} && rm -rf /var/lib/apt/lists/* 
    # clone conformance repository
    RUN mkdir -p \${GOPATH}/src/k8s.io && git clone --branch ${CONFORMANCE_TAG} --depth 1 https://${CONFORMANCE_REPO} \${GOPATH}/src/k8s.io/kubernetes
    WORKDIR \${GOPATH}/src/k8s.io/kubernetes
    # install build dependencies
    RUN go get -u github.com/jteeuwen/go-bindata/go-bindata
    # build all test dependencies
    RUN GOLDFLAGS="--s -w" make all WHAT="cmd/kubectl vendor/github.com/onsi/ginkgo/ginkgo test/e2e/e2e.test"
    ENV TEST_FLAGS="-v --test -check_version_skew=false --test_args=--ginkgo.focus=\[Conformance\]"
    CMD HOME=/go/src/k8s.io/kubernetes KUBECONFIG=/kubeconfig KUBE_OS_DISTRIBUTION=coreos KUBERNETES_CONFORMANCE_TEST=Y go run hack/e2e.go -- \${TEST_FLAGS}
EOF
