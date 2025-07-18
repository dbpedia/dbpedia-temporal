#!/bin/bash

HDFS_TARGET_DIR="/dbpedia-tkg/wikidumps/en/2025-07-01"
BASE_URL="https://dumps.wikimedia.org/enwiki/20250701"


wget -q -O - "$BASE_URL/" | \
grep -oP 'enwiki-20250701-pages-meta-history[0-9]+\.xml-p[0-9]+p[0-9]+\.7z' | \
sort -u | while read FILE; do
    URL="$BASE_URL/$FILE"
    echo ">> Load: $URL"

    hdfs dfs -test -e "$HDFS_TARGET_DIR/$FILE"
    if [ $? -eq 0 ]; then
        echo ">> File already exists. Skip..."
        continue
    fi

    curl -s "$URL" | hdfs dfs -put - "$HDFS_TARGET_DIR/$FILE"

    if [ $? -ne 0 ]; then
        echo "!! Error uploading file: $FILE"
    else
        echo "✓ Uploaded: $FILE"
    fi
done
