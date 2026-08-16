# ah-annotation

GitHub Action to generate ArtifactHub changelog annotations from Git commit history and add them to `Chart.yaml`.

The action parses conventional commit messages between two Git tags and produces an `artifacthub.io/changes` annotation.
Pre-release tags (matching `-rc`) are detected automatically and result in an `artifacthub.io/prerelease` annotation
instead.

## Usage

### Auto-detect tags

Without explicit inputs the action determines the two most recent non-RC tags from the Git history:

```yaml
steps:
  - uses: actions/checkout@v7.0.1
    with:
      fetch-depth: 0
  - uses: volker.raschek/ah-annotations@v0.1.1
```

### Explicit tags

Pass `old-tag` and `new-tag` to control the commit range:

```yaml
steps:
  - uses: actions/checkout@v7.0.1
    with:
      fetch-depth: 0
  - uses: volker.raschek/ah-annotations@v0.1.1
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
| `yq-version`       | no       | `v4.44.6`                            | Version of yq to install.                  |
| `yq-arch`          | no       | auto-detected                        | Architecture of yq binary to download.     |
| `yq-os`            | no       | auto-detected                        | Operating system of yq binary to download. |
| `yq-binary-name`   | no       | `yq`                                 | Name of the yq binary to download.         |
| `yq-download-url`  | no       | auto-built                           | Full URL to download yq from.              |

## Requirements

- The repository must be checked out with full history (`fetch-depth: 0`).
- A `Chart.yaml` file must exist at the path specified by `chart-path`.
- Commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) format.

## Commit type mapping

| Commit type                                      | ArtifactHub kind |
| ------------------------------------------------ | ---------------- |
| `feat`                                           | added            |
| `fix`                                            | fixed            |
| `chore`, `style`, `test`, `ci`, `docs`, `refac`  | changed          |
| `revert`                                         | removed          |
| `sec`                                            | security         |
