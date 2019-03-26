#!/bin/sh 
set -ex
branch=$(git rev-parse --abbrev-ref HEAD)
targetBranch=$1
if [ -z "$targetBranch" ]; then
    echo empty target branch
    exit 2
fi
user=$(git config --get user.name)
if [ -z "$user" ]; then
    echo empty user
    exit 2
fi
hub pull-request -p -h $user:$branch -b $targetBranch
