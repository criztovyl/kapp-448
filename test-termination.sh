#!/usr/bin/env -S bash -ex

test -f counter || echo 0 > counter
counter=$(cat counter)
echo $((counter+1)) > counter

[ "$term_sleep" ] || term_sleep=0

name=$(basename ${0%%.sh})

minikube kubectl -- get events --watch --watch-only > $name-events.log &
minikube kubectl -- get deploy $name --watch --watch-only -o json | jq '. + {ts: now|strftime("%Y-%m-%dT%H:%M:%SZ")}' > $name-deploy.json &

cleanup(){
    kill %1 %2
    trap - EXIT
}

trap cleanup EXIT

kapp deploy -a $name -f - --yes --debug <<EOF | tee $name-kapp.log
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
  labels: &lbl
    app: $name
spec:
  replicas: 1
  selector:
    matchLabels: *lbl
  strategy:
    type: Recreate
  template:
    metadata:
      labels: *lbl
    spec:
      containers:
      - name: container
        image: minikube:5000/simple
        env:
          - name: TERM_SLEEP
            value: "${term_sleep}"
          - name: COUNTER
            value: "${counter}"
EOF

sleep $term_sleep

cleanup

jq '{ts: .ts, generation: .metadata.generation, observedGeneration: .status.observedGeneration, unavailableReplicas: .status.unavailableReplicas}' $name-deploy.json
