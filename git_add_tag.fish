#!/usr/bin/env fish
set match (head -n1 CHANGELOG.md | string match -r '\[(.*)\]')
if [ (count $match) -ne 2 ]
    echo not found tag
    exit 2
end

set tagName $match[2]

if [ -z "$tagName" ]
    echo tagName empty
    exit 2
end

echo tag: $tagName

if [ -z (git tag -l $tagName) ]
    echo create tag
    git tag -a $tagName -m $tagName
end
