#!/bin/bash
NAME=$(yq eval '.metadata.name' $1)
LABELS=$(yq eval '.spec.selector.matchLabels' $1)
REPLICAS=$(yq eval '.spec.replicas' $1)
SERVICEACCOUNT=$(yq eval '.spec.template.spec.serviceAccount' $1)
CONTAINERS=$(yq eval '.spec.template.spec.containers | length' $1)
INITCONTAINERS=$(yq eval '.spec.template.spec.initContainers | length' $1)
VALUES_FILE=values-tmp.yaml
SERVICE_FILE=$(echo $1 | sed 's|deployment|service|g')
ROUTE_FILE=$(echo $1 | sed 's|deployment|route|g')

echo "##########  $NAME Deployment'ı için values.yaml dosyası oluşturuluyor.  ##########"
echo ""
cp values.yaml $VALUES_FILE

yq e ".name = \"$NAME\"" -i "$VALUES_FILE"

for ((i=0; i<CONTAINERS; i++)); do
  name=$(yq e ".spec.template.spec.containers[$i].name" "$1")
  image=$(yq e ".spec.template.spec.containers[$i].image" "$1")
  policy=$(yq e ".spec.template.spec.containers[$i].imagePullPolicy" "$1")

  repo=$(echo "$image" | cut -d ':' -f 1)
  tag=$(echo "$image" | cut -d ':' -f 2)

  yq e ".containers[$i].name = \"$name\"" -i "$VALUES_FILE"
  yq e ".containers[$i].image = {\"policy\": \"$policy\",  \"repository\": \"$repo\", \"tag\": \"$tag\"}" -i "$VALUES_FILE"

  ports=$(yq e ".spec.template.spec.containers[$i].ports" "$1")
  if [[ "$ports" == "null" || -z "$ports" ]]; then
    echo "$name --- Bu konteyner'ın portu bulunmamaktadır."
  else
    yq e ".containers[$i].ports = \"$ports\"" -i "$VALUES_FILE"
  fi


  args=$(yq e ".spec.template.spec.containers[$i].args" "$1" | sed 's/"//g')
  if [[ "$args" == "null" || -z "$args" ]]; then
    echo "$name --- Bu konteyner'ın argümanı bulunmamaktadır."
  else
    yq e ".containers[$i].args = \"$args\"" -i "$VALUES_FILE"
  fi

  env=$(yq e ".spec.template.spec.containers[$i].env" "$1" | sed 's/"//g')
  if [[ "$env" == "null" || -z "$env" ]]; then
    echo "$name --- Bu konteyner'ın environment'i bulunmamaktadır."
  else
    yq e ".containers[$i].env = \"$env\"" -i "$VALUES_FILE"
  fi

  envFrom=$(yq e ".spec.template.spec.containers[$i].envFrom" "$1")
  if [[ "$envFrom" == "null" || -z "$envFrom" ]]; then
    echo "$name --- Bu konteyner'ın env dosyası bulunmamaktadır."
  else
    yq e ".containers[$i].envFrom += \"$envFrom\"" -i "$VALUES_FILE"
    CONFIGMAPS=$(yq e ".spec.template.spec.containers[$i].envFrom[] | select(.configMapRef != null) | .configMapRef.name" "$1")
    for path in $CONFIGMAPS; do
        C_PATH=$(echo "$1" | sed "s|/[^/]*$|/$path.yaml|" | sed 's/deployment/configmap/g')
        DATA=$(yq e '.data' $C_PATH)
        yq eval ".configMaps += [{\"name\": \"$path\", \"data\": load(\"$C_PATH\") | .data}]"  -i "$VALUES_FILE"
    done
  fi

  commands=$(yq e ".spec.template.spec.containers[$i].command" "$1" | sed 's/- //g')
  if [[ "$commands" == "null" || -z "$commands" ]]; then
    echo "$name --- Bu konteyner'ın komutu  bulunmamaktadır."
  else
    yq e ".containers[$i].commands = [\"$commands\"]" -i "$VALUES_FILE"
  fi

  resources=$(yq e ".spec.template.spec.containers[$i].resources" "$1")
  if [[ "$resources" == "null" || -z "$resources" || "$resources" == "{}" ]]; then
    echo "$name --- Bu konteynerda kaynak sınırlaması bulunmamaktadır."
  else
    limits_cpu=$(yq e ".spec.template.spec.containers[$i].resources.limits.cpu" "$1")
    limits_memory=$(yq e ".spec.template.spec.containers[$i].resources.limits.memory" "$1")
    req_cpu=$(yq e ".spec.template.spec.containers[$i].resources.requests.cpu" "$1")
    req_memory=$(yq e ".spec.template.spec.containers[$i].resources.requests.memory" "$1")
    yq e ".containers[$i].resources = {\"limits\": {\"cpu\": \"$limits_cpu\", \"memory\": \"$limits_memory\"}, \"requests\": {\"cpu\": \"$req_cpu\", \"memory\": \"$req_memory\"}}" -i "$VALUES_FILE"
  fi

  volumeMounts=$(yq e ".spec.template.spec.containers[$i].volumeMounts" "$1")
  if [[ "$volumeMounts" == "null" || -z "$volumeMounts" ]]; then
    echo "$name --- Bu konteynerda volumeMount bilgisi bulunmamaktadır."
  else
    yq e ".containers[$i].volumeMounts = \"$volumeMounts\"" -i "$VALUES_FILE"
  fi

  echo $name --- Bu konteyner için values.yaml güncellenmiştir.

done

for ((i=0; i<INITCONTAINERS; i++)); do
  name=$(yq e ".spec.template.spec.initContainers[$i].name" "$1")
  image=$(yq e ".spec.template.spec.initContainers[$i].image" "$1")
  policy=$(yq e ".spec.template.spec.initContainers[$i].imagePullPolicy" "$1")

  repo=$(echo "$image" | cut -d ':' -f 1)
  tag=$(echo "$image" | cut -d ':' -f 2)

  yq e ".initContainers[$i].name = \"$name\"" -i "$VALUES_FILE"
  yq e ".initContainers[$i].image = {\"policy\": \"$policy\",  \"repository\": \"$repo\", \"tag\": \"$tag\"}" -i "$VALUES_FILE"

  ports=$(yq e ".spec.template.spec.initContainers[$i].ports" "$1")
  if [[ "$ports" == "null" || -z "$ports" ]]; then
    echo "$name --- Bu konteyner'ın portu bulunmamaktadır."
  else
    yq e ".initContainers[$i].ports = \"$ports\"" -i "$VALUES_FILE"
  fi

  args=$(yq e ".spec.template.spec.initContainers[$i].args" "$1")
  if [[ "$args" == "null" || -z "$args" ]]; then
    echo "$name --- Bu konteyner'ın argümanı bulunmamaktadır."
  else
    yq e ".initContainers[$i].args = \"$args\"" -i "$VALUES_FILE"
  fi

  env=$(yq e ".spec.template.spec.initContainers[$i].env" "$1" | sed 's/"//g')
  if [[ "$env" == "null" || -z "$env" ]]; then
    echo "$name --- Bu konteyner'ın environment'i bulunmamaktadır."
  else
    yq e ".initContainers[$i].env = \"$env\"" -i "$VALUES_FILE"
  fi

  envFrom=$(yq e ".spec.template.spec.initContainers[$i].envFrom" "$1")
  if [[ "$envFrom" == "null" || -z "$envFrom" ]]; then
    echo "$name --- Bu konteyner'ın env dosyası bulunmamaktadır."
  else
    yq e ".initContainers[$i].envFrom += \"$envFrom\"" -i "$VALUES_FILE"
    CONFIGMAPS=$(yq e ".spec.template.spec.initContainers[$i].envFrom[] | select(.configMapRef != null) | .configMapRef.name" "$1")
    for path in $CONFIGMAPS; do
        C_PATH=$(echo "$1" | sed "s|/[^/]*$|/$path.yaml|" | sed 's/deployment/configmap/g')
        DATA=$(yq e '.data' $C_PATH)
        yq eval ".configMaps += [{\"name\": \"$path\", \"data\": load(\"$C_PATH\") | .data}]"  -i "$VALUES_FILE"
    done
  fi

  commands=$(yq e ".spec.template.spec.initContainers[$i].command" "$1" | sed 's/- //g')
  if [[ "$commands" == "null" || -z "$commands" ]]; then
    echo "$name --- Bu konteyner'ın komutu  bulunmamaktadır."
  else
    yq e ".initContainers[$i].commands = [\"$commands\"]" -i "$VALUES_FILE"
  fi

  resources=$(yq e ".spec.template.spec.initContainers[$i].resources" "$1")
  if [[ "$resources" == "null" || -z "$resources" || "$resources" == "{}" ]]; then
    echo "$name --- Bu konteynerda kaynak sınırlaması bulunmamaktadır."
  else
    limits_cpu=$(yq e ".spec.template.spec.initContainers[$i].resources.limits.cpu" "$1")
    limits_memory=$(yq e ".spec.template.spec.initContainers[$i].resources.limits.memory" "$1")
    req_cpu=$(yq e ".spec.template.spec.initContainers[$i].resources.requests.cpu" "$1")
    req_memory=$(yq e ".spec.template.spec.initContainers[$i].resources.requests.memory" "$1")
    yq e ".initContainers[$i].resources = {\"limits\": {\"cpu\": \"$limits_cpu\", \"memory\": \"$limits_memory\"}, \"requests\": {\"cpu\": \"$req_cpu\", \"memory\": \"$req_memory\"}}" -i "$VALUES_FILE"
  fi

  volumeMounts=$(yq e ".spec.template.spec.initContainers[$i].volumeMounts" "$1")
  if [[ "$volumeMounts" == "null" || -z "$volumeMounts" ]]; then
    echo "$name --- Bu konteynerda volumeMount bilgisi bulunmamaktadır."
  else
    yq e ".initContainers[$i].volumeMounts = \"$volumeMounts\"" -i "$VALUES_FILE"
  fi

  echo $name --- Bu konteyner için values.yaml güncellenmiştir.

done

############ REPLICAS ############
yq e ".replicaCount = \"$REPLICAS\"" -i "$VALUES_FILE"

############ SERVICE ACCOUNT ############
if [[ "$SERVICEACCOUNT" == "null" || -z "$SERVICEACCOUNT" ]]; then
  echo "$NAME -- Bu deployment için ServiceAccount bulunmamaktadır."
else
  yq e ".serviceAccount.create = \"true\"" -i "$VALUES_FILE"
  yq e ".serviceAccount.name = \"$SERVICEACCOUNT\"" -i "$VALUES_FILE"
fi

############ VOLUMES ############

VOLUMES=$(yq e ".spec.template.spec.volumes" "$1")
if [[ "$VOLUMES" == "null" || -z "$VOLUMES" ]]; then
  echo "$NAME -- Bu deployment için volume bilgisi bulunmamaktadır."
else
  yq e ".volumes = \"$VOLUMES\"" -i "$VALUES_FILE"
fi

############ LABELS ############
yq e ".labels = \"$LABELS\"" -i "$VALUES_FILE"

############ SERVICE ############
if [ -e "$SERVICE_FILE" ]; then
    sayi=$(yq eval ".spec.ports[$i].port" "$SERVICE_FILE" | wc -l)
    sum=$(( sayi - 1))
    start=0
    type=$(yq eval '.spec.type' "$SERVICE_FILE")
    yq e ".servicetype = \"$type\"" -i "$VALUES_FILE"
    for i in $(seq $start $sum); do
        port=$(yq eval ".spec.ports[$i].port" "$SERVICE_FILE")
        protocol=$(yq eval ".spec.ports[$i].protocol" "$SERVICE_FILE")
        name=$(yq eval ".spec.ports[$i].name" "$SERVICE_FILE")
        targetport=$(yq eval ".spec.ports[$i].targetPort" "$SERVICE_FILE")
        nodeport=$(yq eval ".spec.ports[$i].nodePort" "$SERVICE_FILE")
        yq e ".service[$i].port = \"$port\"" -i "$VALUES_FILE"
        yq e ".service[$i].protocol = \"$protocol\"" -i "$VALUES_FILE"
        yq e ".service[$i].targetport = \"$targetport\"" -i "$VALUES_FILE"
        if [[ "$name" == "null" || -z "$name" ]]
        then
            echo "$NAME -- Bu deployment'ın $port numaralı portu için isim bulunamamıştır."
        else
            yq e ".service[$i].name = \"$name\"" -i "$VALUES_FILE"
        fi
        if [[ "$nodeport" == "null" || -z "$nodeport" ]]
        then
            echo "$NAME -- Bu deployment NodePort değildir."
        else
            yq e ".service[$i].nodeport = \"$nodeport\"" -i "$VALUES_FILE"
        fi
        yq eval 'del(.service[] | select(.port == "null" or .protocol == "null" or .targetport == "null"))' -i "$VALUES_FILE"
    done
    yq e ".service_state.enabled = true" -i "$VALUES_FILE"
else
    echo "$NAME -- Bu deployment için Service oluşturulmamıştır."
    yq e ".service_state.enabled = false" -i "$VALUES_FILE"
fi

############ ROUTE ############
if [ -e "$ROUTE_FILE" ]; then
    yq e ".route.enabled = true" -i "$VALUES_FILE"
    route_port=$(yq eval '.spec.port.targetPort' "$ROUTE_FILE")
    yq e ".route.port = \"$route_port\"" -i "$VALUES_FILE"
else
    echo "$NAME -- Bu deployment için Route oluşturulmamıştır."
    yq e ".route.enabled = false" -i "$VALUES_FILE"
fi

############ CONFIGMAP ############
CONFIGMAPS=$(yq e '.spec.template.spec.volumes[] | select(.configMap != null) | .configMap.name' "$1")
if [[ "$CONFIGMAPS" == "null" || -z "$CONFIGMAPS" ]]
then
    echo "$NAME -- Bu deployment'ın kullandığı bir configMap yoktur."
else
    for path in $CONFIGMAPS; do
        C_PATH=$(echo "$1" | sed "s|/[^/]*$|/$path.yaml|" | sed 's/deployment/configmap/g')
	DATA=$(yq e '.data' $C_PATH)
        yq eval ".configMaps += [{\"name\": \"$path\", \"data\": load(\"$C_PATH\") | .data}]"  -i "$VALUES_FILE"
    done
fi

############ PERSISTENTVOLUMECLAIM ############
PVC=$(yq e '.spec.template.spec.volumes[] | select(.persistentVolumeClaim != null) | .persistentVolumeClaim.claimName' "$1")
if [[ "$PVC" == "null" || -z "$PVC" ]]
then
    echo "$NAME -- Bu deployment'ın kullandığı bir persistentVolumeClaim yoktur."
    yq e ".pvc_create.enabled = false" -i "$VALUES_FILE"
else
    for path in $PVC; do
        PVC_PATH=$(echo "$1" | sed "s|/[^/]*$|/$path.yaml|" | sed 's/deployment/pvc/g')
	accessmode=$(yq e '.spec.accessModes[]' $PVC_PATH)
	volumemode=$(yq e '.spec.volumeMode' $PVC_PATH)
	storage=$(yq e '.spec.resources.requests.storage' $PVC_PATH)
	storageClassName=$(yq e '.spec.storageClassName' $PVC_PATH)
	if [[ "$storageClassName" == "null" || -z "$storageClassName" ]]
	then
	    yq eval ".persistentVolumeClaims += [{\"name\": \"$path\", \"accessmode\": \"$accessmode\", \"volumemode\": \"$volumemode\", \"storage\": \"$storage\" }]"  -i "$VALUES_FILE"
	else
            yq eval ".persistentVolumeClaims += [{\"name\": \"$path\", \"accessmode\": \"$accessmode\", \"volumemode\": \"$volumemode\", \"storage\": \"$storage\", \"storageClassName\": \"$storageClassName\" }]"  -i "$VALUES_FILE"
	fi
    done
    yq e ".pvc_create.enabled = true" -i "$VALUES_FILE"
fi

############  YAML DÜZENLEYİCİ ############
sed -i 's/|-//g' "$VALUES_FILE"

############ LABELSTATE ############
LABEL_STATE=$(yq eval '.labels | type == "!!str" ' "$VALUES_FILE")
if [[ "$LABEL_STATE" == "true" ]]; then
  KEY=$(yq e ".labels" "$VALUES_FILE" | sed "s/'//g" | awk '{print $1}' | sed 's/://g')
  VALUE=$(yq e ".labels" "$VALUES_FILE" | sed "s/'//g" | awk '{print $2}')
  yq eval '.labels = {}' -i "$VALUES_FILE"
  yq eval ".labels.$KEY = \"$VALUE\"" -i "$VALUES_FILE"
else
  echo "$NAME -- Bu deployment'ın birden fazla label'ı vardır."
fi

echo ""
echo "##########  $NAME Deployment'ı için values.yaml dosyası oluşturulmuştur.  ##########"
