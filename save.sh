#!/bin/bash

# PV'leri kaydet
#mkdir pv
#oc get pv --no-headers -n $1| awk '{print $1}' | while read -r pv_name; do
#    oc get pv -n $1 "$pv_name" -o yaml > "./pv/${pv_name}.yaml"
#    echo "PV $pv_name kaydedildi."
#done

# PVC'leri kaydet
#mkdir pvc
oc get pvc --no-headers -n $1 | awk '{print $1}' | while read -r pvc_name; do
    oc get pvc -n $1 "$pvc_name" -o yaml > "./pvc/${pvc_name}.yaml"
    echo "PVC $pvc_name kaydedildi."
done

# Deployment'lari kaydet
#mkdir deployment
oc get deployment --no-headers -n $1| awk '{print $1}' | while read -r pv_name; do
    oc get deployment "$pv_name" -n $1 -o yaml > "./deployment/${pv_name}.yaml"
    echo "Deployment $pv_name kaydedildi."
done

# ConfigMap'leri kaydet
#mkdir configmap
oc get configmaps --no-headers -n $1 | awk '{print $1}' | while read -r pvc_name; do
    oc get configmaps "$pvc_name" -n $1 -o yaml > "./configmap/${pvc_name}.yaml"
    echo "CM $pvc_name kaydedildi."
done

# Service'leri kaydet
#mkdir service
oc get services --no-headers -n $1| awk '{print $1}' | while read -r pv_name; do
    oc get services "$pv_name" -n $1 -o yaml > "./service/${pv_name}.yaml"
    echo "Service $pv_name kaydedildi."
done

# SCC'leri kaydet
#mkdir scc
#oc get scc --no-headers | awk '{print $1}' | while read -r pvc_name; do
#    oc get scc "$pvc_name" -o yaml > "./scc/${pvc_name}.yaml"
#    echo "SCC $pvc_name kaydedildi."
#done

# Route'leri kaydet
#mkdir route
oc get routes --no-headers -n $1 | awk '{print $1}' | while read -r pv_name; do
    oc get routes -n $1 "$pv_name" -o yaml > "./route/${pv_name}.yaml"
    echo "Route $pv_name kaydedildi."
done

# StatefullSets'leri kaydet
#mkdir statefulset
#oc get statefulsets --no-headers -n $1 | awk '{print $1}' | while read -r pvc_name; do
#    oc get statefulsets "$pvc_name" -n $1 -o yaml > "./statefulset/${pvc_name}.yaml"
#    echo "SFS $pvc_name kaydedildi."
#done

# ServiceAccount'lari kaydet
#mkdir sa
oc get serviceaccounts --no-headers -n $1 | awk '{print $1}' | while read -r pvc_name; do
    oc get serviceaccounts "$pvc_name" -n $1 -o yaml > "./sa/${pvc_name}.yaml"
    echo "SA $pvc_name kaydedildi."
done
