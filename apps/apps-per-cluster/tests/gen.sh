#!/bin/bash

PREFIX="- app-"

VALUES="10 50 100 250 500 1000 10000"
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
