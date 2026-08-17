#!/bin/bash

# ============================================================================
# Generate ArtifactHub changelog annotations from git commit history
# ============================================================================

set -euo pipefail

readonly CHART_FILE="${CHART_FILE:="Chart.yaml"}"
readonly PRERELEASE_PATTERN="\-[a-zA-Z0-9]+([-\.][a-zA-Z0-9]+)*$"

CHANGE_LOG_YAML=""

cleanup() {
  if [[ -n "${CHANGE_LOG_YAML:-}" && -f "${CHANGE_LOG_YAML}" ]]; then
    rm -f "${CHANGE_LOG_YAML}"
  fi
}
trap cleanup EXIT

if [[ ! -f "${CHART_FILE}" ]]; then
  echo "ERROR: ${CHART_FILE} not found!" >&2
  exit 1
fi

# Determine old and new tags
DEFAULT_NEW_TAG="$(git tag --sort=-version:refname | grep --invert-match --perl-regexp "${PRERELEASE_PATTERN}" | head --lines 1)"
DEFAULT_OLD_TAG="$(git tag --sort=-version:refname | grep --invert-match --perl-regexp "${PRERELEASE_PATTERN}" | head --lines 2 | tail --lines 1)"

if [[ -n "${INPUT_OLD_TAG:-}" ]]; then
  OLD_TAG="${INPUT_OLD_TAG}"
else
  OLD_TAG="${DEFAULT_OLD_TAG}"
fi

if [[ -n "${INPUT_NEW_TAG:-}" ]]; then
  NEW_TAG="${INPUT_NEW_TAG}"
else
  NEW_TAG="${DEFAULT_NEW_TAG}"
fi

if [[ -z "$(git tag --list "${OLD_TAG}")" ]]; then
  echo "ERROR: Tag '${OLD_TAG}' not found!" >&2
  exit 1
fi

if [[ -z "$(git tag --list "${NEW_TAG}")" ]]; then
  echo "ERROR: Tag '${NEW_TAG}' not found!" >&2
  exit 1
fi

if [[ "${NEW_TAG}" =~ ${PRERELEASE_PATTERN} ]]; then
  echo "INFO: Tag '${NEW_TAG}' is a prerelease, setting prerelease annotation and skipping changelog."
  yq --no-colors --inplace ".annotations.\"artifacthub.io/prerelease\" = \"true\" | sort_keys(.)" "${CHART_FILE}"
  exit 0
fi

CHANGE_LOG_YAML="$(mktemp)"
echo "[]" > "${CHANGE_LOG_YAML}"

map_type_to_kind() {
  case "${1}" in
    feat)
      echo "added"
      ;;
    fix)
      echo "fixed"
      ;;
    chore|style|test|ci|docs|refac)
      echo "changed"
      ;;
    revert)
      echo "removed"
      ;;
    sec)
      echo "security"
      ;;
    *)
      echo "skip"
      ;;
  esac
}

COMMIT_TITLES="$(git log --pretty=format:"%s" "${OLD_TAG}..${NEW_TAG}")"

echo "INFO: Generate change log entries from ${OLD_TAG} until ${NEW_TAG}"

while IFS= read -r line; do
  if [[ "${line}" =~ ^([a-zA-Z]+)(\([^\)]+\))?\:\ (.+)$ ]]; then
    TYPE="${BASH_REMATCH[1]}"
    KIND="$(map_type_to_kind "${TYPE}")"

    if [[ "${KIND}" == "skip" ]]; then
      continue
    fi

    DESC="${BASH_REMATCH[3]}"

    echo "- ${KIND}: ${DESC}"

    jq --arg kind "${KIND}" --arg description "${DESC}" '. += [ $ARGS.named ]' < "${CHANGE_LOG_YAML}" > "${CHANGE_LOG_YAML}.new"
    mv "${CHANGE_LOG_YAML}.new" "${CHANGE_LOG_YAML}"
  fi
done <<< "${COMMIT_TITLES}"

if [[ -s "${CHANGE_LOG_YAML}" ]]; then
  yq --inplace --input-format json --output-format yml "${CHANGE_LOG_YAML}"
  yq --no-colors --inplace ".annotations.\"artifacthub.io/changes\" |= loadstr(\"${CHANGE_LOG_YAML}\") | sort_keys(.)" "${CHART_FILE}"
else
  echo "ERROR: Changelog file is empty: ${CHANGE_LOG_YAML}" >&2
  exit 1
fi
