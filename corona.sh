#!/bin/bash
# Get population of california by county (json)
POPULATION_URL=https://www.california-demographics.com/counties_by_population
POPULATION=$(curl -s $POPULATION_URL | tr '\n' ' ' | sed -e 's/\s\s*/ /g' | sed -e 's/.*th>//g' | sed -e 's/<td colspan.*//'g | sed -e 's/<tr>/\n/g' | sed -e 's/.*demographics">/"/g' | sed -e 's/<\/a.*<td>\ /":/g' | sed -e 's/\ <\/td.*//g' | sed -e 's/,//g' | sed -e 's/<\/tr>//g' | tr '\n' ',' | sed -e 's/^\s*,//g' | sed -e 's/,\s*$//g' | sed -e 's/\ County//g' | sed -e 's/\(.*\)/{\1}/g' | jq --slurp -c '.[]')

# Get total infection from yesterday
DATA_SOURCE=926fd08f-cc91-4828-af38-bd45de97f8c3
TARGET_DATE=$(date +"%Y-%m-%d" --date="-2 days")
TARGET_URL=https://data.ca.gov/api/3/action/datastore_search?resource_id=$DATA_SOURCE\&filters=%7B%22date%22:%22$TARGET_DATE%22%7D
result=$(curl -s $TARGET_URL  | jq -c '.result.records[]')
while IFS= read -r county; do
  this_totalcountconfirmed=$(echo $county | jq -r '.totalcountconfirmed')
  this_county=$(echo $county | jq -r '.county')
  if [[ -z $(echo "$POPULATION" | grep "$this_county") ]]; then
    continue
  fi
  this_population=$(echo "$POPULATION" | jq --raw-output '.["'"$this_county"'"]')
  printf -v this_tmp_percentage "%03d" $(($this_totalcountconfirmed*10000/$this_population))
  this_percentage=$(echo "$this_tmp_percentage" | sed -e 's/\(.\)\(.\)\(.\)/\1.\2\3\%/g' | sed -e 's/00\./0./g')
  echo "$this_percentage,$this_county"
done <<< "$result"


