#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if ! [ -d state/ ]; then
  exit "No State, exiting"
  exit 1
fi

source state/env.sh
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:?"env!"}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:?"env!"}
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:?"env!"}
CONCOURSE_DOMAIN=${CONCOURSE_DOMAIN:?"env!"}
CONCOURSE_USERNAME=${CONCOURSE_USERNAME:?"env!"}
CONCOURSE_PASSWORD=${CONCOURSE_PASSWORD:?"env!"}
CONCOURSE_BOSH_ENV=${CONCOURSE_BOSH_ENV:?"env!"}
DOMAIN=${DOMAIN:?"env!"}
CONCOURSE_TARGET=${CONCOURSE_TARGET:?"env!"}
CONCOURSE_PIPELINE=${CONCOURSE_PIPELINE:?"env!"}
BBL_LBS_CERT=${BBL_LBS_CERT:?"env!"}
BBL_LBS_KEY=${BBL_LBS_KEY:?"env!"}
STATE_REPO_URL=${STATE_REPO_URL:?"env!"}
STATE_REPO_PRIVATE_KEY=${STATE_REPO_PRIVATE_KEY:?"env!"}

mkdir -p bin
PATH=$(pwd)/bin:$PATH

if ! [ -f bin/bbl ]; then
  curl -L "https://github.com/cloudfoundry/bosh-bootloader/releases/download/v3.0.4/bbl-v3.0.4_osx" > bin/bbl
  chmod +x bin/bbl
fi

if ! [ -f bin/fly ]; then
  curl -L "http://$CONCOURSE_DOMAIN/api/v1/cli?arch=amd64&platform=darwin" > bin/fly
  chmod +x bin/fly
fi

if ! fly targets | grep $CONCOURSE_TARGET; then
  fly login \
    --target $CONCOURSE_TARGET \
    --concourse-url "http://$CONCOURSE_DOMAIN" \
    --username admin \
    --password $CONCOURSE_PASSWORD \
  ;
fi

if ! fly pipelines -t $CONCOURSE_TARGET | grep $CONCOURSE_PIPELINE; then
  fly set-pipeline \
    --target $CONCOURSE_TARGET \
    --pipeline $CONCOURSE_PIPELINE \
    --config cf-deployment-pipeline.yml \
    --var bbl_env_name="$CONCOURSE_BOSH_ENV" \
    --var bbl_aws_region="$AWS_DEFAULT_REGION" \
    --var bbl_aws_access_key_id="$AWS_ACCESS_KEY_ID" \
    --var bbl_aws_secret_access_key="$AWS_SECRET_ACCESS_KEY" \
    --var bbl_lbs_ssl_cert="$BBL_LBS_CERT" \
    --var bbl_lbs_ssl_signing_key="$BBL_LBS_KEY" \
    --var state_repo_url="$STATE_REPO_URL" \
    --var state_repo_private_key="$STATE_REPO_PRIVATE_KEY" \
    --var system_domain="$DOMAIN" \
    --non-interactive \
  ;
fi
