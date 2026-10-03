#!/usr/bin/env bash
# Runs the same build/test steps as .github/workflows/ci.yml, using the
# moongas package directories already checked out locally in or symlinked into
# the root directory of this repository
set -euo pipefail

# Below is a Bash idiom used to reliably anchor a script's working directory 
# to the directory where the script itself is located (the repository root), 
# regardless of where you invoke it from in the terminal.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "==> Build and Install Go Module"
(cd moongas-mediascan-go && go install ./...)

echo "==> Run Go scan-to-artists-yaml"
go -C "$REPO_ROOT/moongas-mediascan-go" run ./cmd/scan-to-artists-yaml "$REPO_ROOT/mediascan-config.yml" "$REPO_ROOT/mediascan-artists.yml" "$REPO_ROOT"

echo "==> Activating Python Virtual Environment"
source "$REPO_ROOT/.venv/bin/activate"

echo "==> Upgrade Pip"
python -m pip install --upgrade pip

echo "==> Install Local Python Packages"
python -m pip install pandas-stubs
python -m pip install -e ./moongas-mediascan-python
python -m pip install -e ./moongas-mediatest-python-pytest
python -m pip install -e ./moongas-mediascripts-python
python -m pip install -e ./moongas-mediatunes-svc-python-blacksheep

echo "==> Run mediatest on moongas-collection"
python -m mediatest --log-level=DEBUG -v -k "not test_album_cover_exists and not test_album_dir_contains_media_files" "$REPO_ROOT/mediatest-config.yml"
