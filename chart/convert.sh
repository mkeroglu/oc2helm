#!/bin/bash
ls ../deployment/ | while read -r deployment; do
	./start.sh ../deployment/$deployment
	cp values-tmp.yaml values/$deployment
done
