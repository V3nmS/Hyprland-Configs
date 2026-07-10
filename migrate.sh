#!/bin/bash

SRC="$HOME/.config/hypr/generated"
DEST="$HOME/.config/hypr/lua"

for file in "$SRC"/*.conf; do
    name=$(basename "$file" .conf)

    {
        echo 'return [['
        cat "$file"
        echo ']]'
    } >"$DEST/$name.lua"

    echo "Migrated: $name.lua"
done
