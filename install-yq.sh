#!/bin/bash

set -euo pipefail

internal_yq_version=v4.44.6 # renovate: datasource=github-releases depName=mikefarah/yq versioning=semver

# Use :- for unset and handle empty strings from composite action inputs
YQ_BINARY_NAME="${YQ_BINARY_NAME:="yq"}"
YQ_OS="${YQ_OS:="$(uname -s | tr '[:upper:]' '[:lower:]')"}"
YQ_ARCH="${YQ_ARCH:="$(uname -m)"}"
YQ_VERSION="${YQ_VERSION:="${internal_yq_version}"}"

# Determine OS
case "${YQ_OS:-}" in
  linux*)     ;;
  darwin*)    ;;
  *)          echo "ERROR: Unsupported OS: $(uname -s)"; exit 1;;
esac


# Determine architecture
case "${YQ_ARCH:-}" in
  amd64*  | x86_64*)  YQ_ARCH="amd64" ;;
  aarch64 | arm64*)     YQ_ARCH="arm64" ;;
  *)          echo "ERROR: Unsupported architecture: $(uname -m)"; exit 1;;
esac

# Build download URL if not explicitly provided
if [[ -z "${YQ_DOWNLOAD_URL:-}" ]]; then
  YQ_DOWNLOAD_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY_NAME}_${YQ_OS}_${YQ_ARCH}.tar.gz"
fi

# Determine install path
if [[ "$(id -u)" != "0" ]]; then
  home="$(getent passwd "$(id -u)" | cut --delimiter ":" --field "6")"
  mkdir --parents "${home}/.local/bin"
  bin_path="${home}/.local/bin/yq"
else
  bin_path="/usr/local/bin/yq"
fi

# Download and extract yq binary from .tar.gz
if [[ "${YQ_DOWNLOAD_URL}" =~ \.tar\.gz$ ]]; then
  echo "INFO: Downloading and extracting yq from ${YQ_DOWNLOAD_URL}..."
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' EXIT

  curl \
    --fail \
    --location \
    --output /dev/stdout \
    --silent \
    --show-error "${YQ_DOWNLOAD_URL}" | \
    tar \
      --extract \
      --gzip \
      --directory "${tmp_dir}" \
      --file /dev/stdin

  mv "${tmp_dir}/${YQ_BINARY_NAME}_${YQ_OS}_${YQ_ARCH}" "${bin_path}"

# Download yq binary directly
else
  echo "INFO: Downloading yq from ${YQ_DOWNLOAD_URL}..."

  curl \
    --fail \
    --location \
    --output "${bin_path}" \
    --silent \
    --show-error "${YQ_DOWNLOAD_URL}"
fi

chmod +x "${bin_path}"

yq_installed_version="$("${bin_path}" --version)"
echo "INFO: Installed ${yq_installed_version} in ${bin_path}"

# Ensure yq is in PATH for subsequent steps
if [[ -n "${GITHUB_PATH:-}" ]]; then
  "$(dirname "${bin_path}")" >> "${GITHUB_PATH}"
fi