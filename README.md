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
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0
  - uses: volker.raschek/ah-annotation@v1
```

### Explicit tags

Pass `old-tag` and `new-tag` to control the commit range:

```yaml
steps:
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0
  - uses: volker.raschek/ah-annotation@v1.0.0
    with:
      old-tag: v1.0.0
      new-tag: v2.0.0
```

## Inputs

| Name      | Required | Default       | Description                          |
| --------- | -------- | ------------- | ------------------------------------ |
| `old-tag` | no       | auto-detected | Start tag for changelog generation.  |
| `new-tag` | no       | auto-detected | End tag for changelog generation.    |

## Requirements

- The repository must be checked out with full history (`fetch-depth: 0`).
- A `Chart.yaml` file must exist in the working directory.
- Commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) format.

## Commit type mapping

| Commit type                                      | ArtifactHub kind |
| ------------------------------------------------ | ---------------- |
| `feat`                                           | added            |
| `fix`                                            | fixed            |
| `chore`, `style`, `test`, `ci`, `docs`, `refac`  | changed          |
| `revert`                                         | removed          |
| `sec`                                            | security         |
