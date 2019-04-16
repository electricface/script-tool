#!/usr/bin/env fish

function proj_need_tag
    set proj_dir $argv[1]
    
    cd $proj_dir
    set desc (git describe --tags)

    if string match -- '*-g*' $desc >/dev/null
        echo $proj_dir $desc
    end
end

set projs $HOME/projects
set gosrc $GOPATH/src
set proj_dir_list \
"$gosrc/pkg.deepin.io/dde/daemon" \
"$gosrc/pkg.deepin.io/dde/api" \
"$gosrc/pkg.deepin.io/dde/startdde" \
"$gosrc/pkg.deepin.io/lib" \
"$gosrc/github.com/linuxdeepin/go-x11-client" \
"$gosrc/github.com/linuxdeepin/go-dbus-factory" \
"$projs/lastore-daemon" \
"$projs/deepin-feedback" \
"$projs/dbus-factory" \
"$projs/go-gir-generator" \
"$projs/deepin-desktop-schemas"

for p in $proj_dir_list
    proj_need_tag $p
end



