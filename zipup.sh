PASSWORD=$(curl -s "https://www.dinopass.com/password/simple")

ZIPNAME=$1 # "OFFICIAL-alf-prod-2019-12-17-split-3.zip"

zip -P "$PASSWORD" "$ZIPNAME" *-split-*csv

echo "Complete: $ZIPNAME encrypted with $PASSWORD"
