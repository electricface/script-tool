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

# delete user remote branch
git push $user :$branch
git checkout $targetBranch
git pull origin $targetBranch
git push $user $targetBranch
# delete local branch
git branch -D $branch
