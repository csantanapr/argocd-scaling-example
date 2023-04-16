#!/bin/bash

PREFIX="- app-"

VALUES="1 2 10 50 100 250 375 500 1000 2000 5000 6000 7000 8000 9000 10000"
for COUNTER_VALUES in $VALUES
do
  APPS=$COUNTER_VALUES
  COUNTER=0
  echo "items:" > values-${APPS}.yaml
  for COUNTER in $(seq $APPS)
  do
    echo "${PREFIX}${COUNTER}" >> values-${APPS}.yaml
    let COUNTER++
  done
done
