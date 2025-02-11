#!/bin/bash

git merge-base origin/main HEAD | xargs -i git diff --name-only {} | grep '^problems/' | cut -d'/' -f2 | sort -u | while read -r problem; do
    echo "Running tests for $problem"
    bash tests/check_problem.sh $problem
done