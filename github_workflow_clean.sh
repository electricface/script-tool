#!/bin/sh 
set -ex
branch=$(git rev-parse --abbrev-ref HEAD)

user=$(git config --get user.name)
if [ -z "$user" ]; then
    echo empty user
    exit 2
fi

headSha=$(git rev-parse HEAD)

prInfo=$(hub pr list -s all -h $user:$branch -f "%S,%B,%sH%n"|grep ,$headSha)
prState=$(echo $prInfo|cut -d , -f 1)
prBaseBranch=$(echo $prInfo|cut -d , -f 2)

if [ "$prState" != closed ]; then
    echo pull request not closed
    exit 2
fi

if [ -z "$prBaseBranch" ]; then
    echo empty prBaseBranch
    exit 2
fi

if git remote| grep upstream >/dev/null; then
    forkRemote=origin
    upstreamRemote=upstream
else
    forkRemote=$user
    upstreamRemote=origin
fi

# delete fork remote branch
git push $forkRemote :$branch
git checkout $prBaseBranch
git pull $upstreamRemote $prBaseBranch
git push $forkRemote $prBaseBranch
# delete local branch
git branch -D $branch
