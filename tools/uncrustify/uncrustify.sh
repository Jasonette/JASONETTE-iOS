#!/usr/bin/env sh

# Execute this command in the root directory
find ./xcode/Jasonette -name "*.h" | xargs uncrustify -c ./tools/uncrustify/uncrustify.cfg --replace --no-backup
find ./xcode/Jasonette -name "*.m" | xargs uncrustify -c ./tools/uncrustify/uncrustify.cfg --replace --no-backup