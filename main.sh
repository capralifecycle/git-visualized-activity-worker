#!/bin/bash
set -eu

source lib.sh

if [ -n "${DATA_DIR:-}" ]; then
  echo "Storing data in $DATA_DIR"
  root=$DATA_DIR
else
  root=$PWD
fi

# When running in Docker, we need some extra parameters and setup.
if [ -e /.dockerenv ]; then
  if [ -z "${CALS_GITHUB_TOKEN:-}" ]; then
    echo "Missing CALS_GITHUB_TOKEN environment varible"
    echo "It should be a GitHub Personal Access Token with scope=repo"
  fi

  echo -e "protocol=https\nhost=github.com\nusername=git\npassword=$CALS_GITHUB_TOKEN\n" | git credential approve
fi

install_cals_cli
fetch_gva

fetch_cals_tools
setup_mailmap

process_repos

upload_commits
invalidate_distribution
