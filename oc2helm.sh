#!/bin/bash
NAMESPACE=$1
./start.sh $NAMESPACE
./chart/convert.sh
