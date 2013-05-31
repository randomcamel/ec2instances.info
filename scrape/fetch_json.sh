#!/bin/bash

BASE=http://aws.amazon.com/ec2/pricing/
INDEX=pricing_index.html

get_index_page () {
    echo "Fetching index page $BASE..."
    wget --timestamping -q -O $INDEX http://aws.amazon.com/ec2/pricing/
}

# limiting to on-demand right now, since reserve data is different.
get_json_files () {
    local files=`grep /json/ $INDEX | perl -lne 'm#(/.*?\.json)#; print $1' | grep od`

    for price_json in $files; do
        fname=`basename $price_json`
        echo "Fetching $fname..."
        wget --timestamping -q -O json_data/$fname $BASE/json/$fname
    done
}

get_index_page
get_json_files
