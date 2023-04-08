#!/bin/bash

APPS=10
COUNTER=0
echo "items:" > values-${APPS}.yaml
for COUNTER in $(seq $APPS)
do
  echo "- app-${COUNTER}" >> values-${APPS}.yaml
  let COUNTER++
done

APPS=100
COUNTER=0
echo "items:" > values-${APPS}.yaml
for COUNTER in $(seq $APPS)
do
  echo "- app-${COUNTER}" >> values-${APPS}.yaml
  let COUNTER++
done

APPS=1000
COUNTER=0
echo "items:" > values-${APPS}.yaml
for COUNTER in $(seq $APPS)
do
  echo "- app-${COUNTER}" >> values-${APPS}.yaml
  let COUNTER++
done

APPS=10000
COUNTER=0
echo "items:" > values-${APPS}.yaml
for COUNTER in $(seq $APPS)
do
  echo "- app-${COUNTER}" >> values-${APPS}.yaml
  let COUNTER++
done
