#!/usr/bin/env bash

set -e

BUCKET_NAME=hotsapi

setup_s3() {
    TEMP_FILE='/tmp/temp_replay'
    BUCKETS_EXIST=`aws --endpoint-url=$AWS_ENDPOINT s3api list-buckets | jq -r '.Buckets[].Name' | wc -l`
    if [[ "$BUCKETS_EXIST" != "0" ]]; then
        aws --endpoint-url=$AWS_ENDPOINT s3 rb s3://$BUCKET_NAME --force
    fi
    aws --endpoint-url=$AWS_ENDPOINT s3api create-bucket --bucket $BUCKET_NAME

    rm -f $TEMP_FILE
    touch $TEMP_FILE

    for counter in {1..21}; do
       aws --endpoint-url=$AWS_ENDPOINT s3 cp $TEMP_FILE s3://$BUCKET_NAME/replay$counter.StormReplay
    done
}

setup_db() {
    AFTER_90_DAYS=`date -d "-91 days" -Id`
    BEFORE_90_DAYS=`date -d "-89 days" -Id`
    AFTER_30_DAYS=`date -d "-31 days" -Id`
    BEFORE_30_DAYS=`date -d "-29 days" -Id`
    AFTER_7_DAYS=`date -d "-8 days" -Id`
    BEFORE_7_DAYS=`date -d "-6 days" -Id`
    NOW=`date -Id`

    cat <<EOD | mysql -h $DB_HOST -u root -p$DB_PASSWORD
    DROP TABLE IF EXISTS hotsapi.replays;

    CREATE TABLE hotsapi.replays (
      id INT NOT NULL,
      filename VARCHAR(45) NOT NULL,
      processed INT NOT NULL,
      deleted INT NOT NULL,
      game_type VARCHAR(45) NOT NULL,
      game_date DATETIME NOT NULL,
      created_at DATETIME NOT NULL,
      PRIMARY KEY (id));

    TRUNCATE hotsapi.replays;

    INSERT INTO hotsapi.replays
    VALUES
    (1, 'replay1', 1, 0, 'HeroLeague', '$AFTER_90_DAYS', '$NOW'),
    (2, 'replay2', 1, 0, 'TeamLeague', '$AFTER_90_DAYS', '$NOW'),
    (3, 'replay3', 1, 0, 'StormLeague', '$AFTER_90_DAYS', '$NOW'),
    (4, 'replay4', 1, 0, 'HeroLeague', '$BEFORE_90_DAYS', '$NOW'),
    (5, 'replay5', 1, 0, 'TeamLeague', '$BEFORE_90_DAYS', '$NOW'),
    (6, 'replay6', 1, 0, 'StormLeague', '$BEFORE_90_DAYS', '$NOW'),
    (7, 'replay7', 1, 0, 'HeroLeague', '$AFTER_30_DAYS', '$NOW'),
    (8, 'replay8', 1, 0, 'TeamLeague', '$AFTER_30_DAYS', '$NOW'),
    (9, 'replay9', 1, 0, 'StormLeague', '$AFTER_30_DAYS', '$NOW'),
    (10, 'replay10', 1, 0, 'HeroLeague', '$BEFORE_30_DAYS', '$NOW'),
    (11, 'replay11', 1, 0, 'TeamLeague', '$BEFORE_30_DAYS', '$NOW'),
    (12, 'replay12', 1, 0, 'StormLeague', '$BEFORE_30_DAYS', '$NOW'),
    (13, 'replay13', 1, 0, 'HeroLeague', '$NOW', '$AFTER_7_DAYS'),
    (14, 'replay14', 1, 0, 'TeamLeague', '$NOW', '$AFTER_7_DAYS'),
    (15, 'replay15', 1, 0, 'StormLeague', '$NOW', '$AFTER_7_DAYS'),
    (16, 'replay13', 1, 0, 'HeroLeague', '$AFTER_30_DAYS', '$AFTER_7_DAYS'),
    (17, 'replay14', 1, 0, 'TeamLeague', '$AFTER_30_DAYS', '$AFTER_7_DAYS'),
    (18, 'replay15', 1, 0, 'StormLeague', '$AFTER_30_DAYS', '$AFTER_7_DAYS'),
    (19, 'replay16', 1, 0, 'HeroLeague', '$NOW', '$BEFORE_7_DAYS'),
    (20, 'replay17', 1, 0, 'TeamLeague', '$NOW', '$BEFORE_7_DAYS'),
    (21, 'replay18', 1, 0, 'StormLeague', '$NOW', '$BEFORE_7_DAYS')
EOD
}

main() {
    setup_db
    setup_s3
}

main
