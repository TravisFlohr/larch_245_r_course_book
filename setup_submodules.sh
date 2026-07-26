#!/bin/bash

REPO_URL="git@github.com:TravisFlohr/teaching_boilerplate.git"
SUBMODULE_DIR="teaching_boilerplate"

# Exit if not a git repo
if [ ! -d ".git" ]; then
  echo "Not a git repository. Skipping submodule initialization."
  exit 0
fi

# Add submodule if missing
if [ ! -d "$SUBMODULE_DIR" ]; then
  echo "Adding teaching_boilerplate submodule..."
  git submodule add "$REPO_URL" "$SUBMODULE_DIR"
fi

# Always ensure it is initialized
git submodule update --init --recursive

echo "Submodule ready."