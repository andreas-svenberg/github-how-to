#!/usr/bin/env bash
# Counts the files in a folder and writes a short report.
# This version has two deliberate notes for ShellCheck on the line with count.
set -euo pipefail

folder=${1:-.}
count=$(ls $folder | wc -l)
echo "The folder $folder contains $count files"
