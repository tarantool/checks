#!/usr/bin/env bash

set -e -o pipefail

if [[ $DIST == "noble" ]] || [[ $DIST == "bookworm" ]]; then
  curl -LsSf https://www.tarantool.io/release/3/installer.sh | sudo bash
elif [[ $DIST == "impish" ]] || [[ $DIST == "jammy" ]]; then
  curl -LsSf https://www.tarantool.io/release/2/installer.sh | sudo bash
else
  curl -LsSf https://www.tarantool.io/release/1.10/installer.sh | sudo bash
fi

sudo apt install -y tt
tt version
