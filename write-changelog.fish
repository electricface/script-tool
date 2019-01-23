#!/usr/bin/env fish
set oldTagName $argv[1]
set newTagName $argv[2]


echo "[$newTagName]" (date -u +"%Y-%m-%d") > changelog.temp
git log $oldTagName..HEAD --pretty=format:'*   %s' >> changelog.temp
echo -e '\n' >> changelog.temp
cat changelog.temp

git checkout CHANGELOG.md
cat changelog.temp CHANGELOG.md > changelog.new
rm changelog.temp
mv changelog.new CHANGELOG.md
