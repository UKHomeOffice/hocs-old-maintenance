set +x
# This script takes a big file ($1) and splits it into lots of smaller files.
# A bug here means you'll need to edit the generated -aa file manually and remove the first line (as the header gets duplicated)

FILENAME=$1# e.g. alf-prod-1970-01-01.csv
SPLITNAME=$2 # e.g. alf-prod-1970-01-01-split-
HEADER=$(head -n1 "$FILENAME")
HEADERFILE=$(mktemp)

echo "$HEADER" > "$HEADERFILE"

split -l 500000 "$FILENAME" "$SPLITNAME"

for file in *-split-*; do
  echo "$file"
  cat "$HEADERFILE" "$file" > "$file.csv"
  rm "$file"
done
