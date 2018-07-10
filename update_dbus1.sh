#!/bin/bash
set -x
set -e

godbus_dir=$GOPATH/src/github.com/godbus/dbus
pushd $godbus_dir
git checkout master
git pull
commit_id=$(git rev-parse HEAD)
echo $commit_id
popd

cd $GOPATH/src/pkg.deepin.io/lib/
rm -rf dbus1
mkdir dbus1
cd dbus1

cp -rv $godbus_dir/* .
sed -i 's#"context"#"golang.org/x/net/context"#' *.go
sed -i 's#"github.com/godbus/dbus#"pkg.deepin.io/lib/dbus1#' */*.go

# skip TestSystemBus
sed -i '/func TestSystemBus/a t.Skip("do not call SystemBus")' conn_test.go
find -type f -name '*.go' -exec goimports -w '{}' \;
echo $commit_id > git_commit

# do test
go test

