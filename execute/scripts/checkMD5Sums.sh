#!/bin/bash

set -euo pipefail


MD5_URL="https://dumps.wikimedia.org/enwiki/20250701/enwiki-20250701-md5sums.txt"
HDFS_TARGET_DIR="/dbpedia-tkg/wikidumps/en/2025-07-01"


EXPECTED_MD5S="md5_expected_sorted.txt"
ACTUAL_MD5S="md5_actual_sorted.txt"
HDFS_FILE_LIST="hdfs_files_sorted.txt"


echo "Load MD5-Checksums..."
curl -s "$MD5_URL" \
  | grep '\.7z$' \
  | sort -k2 > "$EXPECTED_MD5S"

echo "Found expected Checksums:"
cat "$EXPECTED_MD5S"


echo "Get list of .7z-Files from HDFS: $HDFS_TARGET_DIR..."
hdfs dfs -ls "$HDFS_TARGET_DIR" \
  | awk '{print $NF}' \
  | grep '\.7z$' \
  | sort > "$HDFS_FILE_LIST"

echo "Found files in HDFS:"
cat "$HDFS_FILE_LIST"


echo "Calculate MD5-Checksums of HDFS-Files..."
> "$ACTUAL_MD5S"

while read -r hdfs_path; do
  filename=$(basename "$hdfs_path")
  echo "Check File: $filename"
  checksum=$(hdfs dfs -cat "$hdfs_path" | md5sum | awk '{print $1}')
  echo "$checksum  $filename" >> "$ACTUAL_MD5S"
done < "$HDFS_FILE_LIST"

sort -k2 -o "$ACTUAL_MD5S" "$ACTUAL_MD5S"


echo ""
echo "=== Comparison ==="
diff -u "$EXPECTED_MD5S" "$ACTUAL_MD5S" || {
  echo ""
  echo "❌ Wrong Checksums found!"
  exit 1
}

echo ""
echo "✅ All MD5-Checksums are equal."


