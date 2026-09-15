# ah-annotation

GitHub Action to generate [ArtifactHub
annotations](https://artifacthub.io/docs/topics/annotations/helm/#supported-annotations) from Git commit history and add
them to `Chart.yaml`.

The action parses conventional commit messages between two Git tags and produces an `artifacthub.io/changes` annotation.
Pre-release tags according to [SemVer 2.0](https://semver.org/) (e.g. `-alpha`, `-beta.1`, `-rc.2`) are detected
automatically and additionally result in an `artifacthub.io/prerelease` annotation.

## Usage

### Auto-detect tags

Without explicit inputs the action uses the currently checked out tag as end tag and the most recent stable
(non-pre-release) tag as start tag:

```yaml
steps:
  - uses: actions/checkout@v7.0.1
    with:
      fetch-depth: 0
  - uses: volker.raschek/ah-annotations@v0.2.2
```

### Explicit tags

Pass `old-tag` and `new-tag` to control the commit range:

```yaml
steps:
  - uses: actions/checkout@v7.0.1
    with:
      fetch-depth: 0
  - uses: volker.raschek/ah-annotations@v0.2.2
    with:
      old-tag: v1.0.0
      new-tag: v2.0.0
```

## Inputs

| Name               | Required | Default                              | Description                                |
| ------------------ | -------- | ------------------------------------ | ------------------------------------------ |
| `chart-path`       | no       | `${{ github.workspace }}/Chart.yaml` | Path to the Helm chart file.               |
| `old-tag`          | no       | auto-detected                        | Start tag for changelog generation.        |
| `new-tag`          | no       | auto-detected                        | End tag for changelog generation.          |
| `yq-version`       | no       | `v4.53.6`                            | Version of yq to install.                  |
| `yq-arch`          | no       | auto-detected                        | Architecture of yq binary to download.     |
| `yq-os`            | no       | auto-detected                        | Operating system of yq binary to download. |
| `yq-binary-name`   | no       | `yq`                                 | Name of the yq binary to download.         |
| `yq-download-url`  | no       | auto-built                           | Full URL to download yq from.              |

## Requirements

- The repository must be checked out with full history (`fetch-depth: 0`).
- A `Chart.yaml` file must exist at the path specified by `chart-path`.
- Commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) format.

## Pre-releases

Tags containing a hyphen-separated pre-release identifier according to [SemVer 2.0](https://semver.org/) are treated as
pre-releases (e.g. `v1.0.0-alpha`, `v1.0.0-beta.1`, `v2.0.0-rc.2`). When `new-tag` is a pre-release tag, the action sets
`artifacthub.io/prerelease: "true"` in `Chart.yaml` in addition to the generated changelog.

When auto-detecting tags (no explicit `old-tag`/`new-tag`), the end tag is the tag of the checked out commit - including
pre-releases - while the start tag is always the most recent stable tag.

## Commit type mapping

| Commit type                                      | ArtifactHub kind |
| ------------------------------------------------ | ---------------- |
| `feat`                                           | added            |
| `fix`                                            | fixed            |
| `chore`, `style`, `test`, `ci`, `docs`, `refac`  | changed          |
| `revert`                                         | removed          |
| `sec`                                            | security         |
