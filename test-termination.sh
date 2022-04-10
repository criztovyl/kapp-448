#!/usr/bin/env -S bash -ex

[ "$term_sleep" ] || term_sleep=0

name=$(basename ${0%%.sh})

case $1 in
    --report)
        [ -f $name-pids ] && eval kill $(cat $name-pids)
        rm -f $name-pids
       #jq '{ts: .ts, formattedTime: .ts|strftime("%H:%M:%SZ"), generation: .metadata.generation, observedGeneration: .status.observedGeneration, unavailableReplicas: .status.unavailableReplicas, updatedReplicas: .status.updatedReplicas}' $name-deploy.json
        jq '{generation: .metadata.generation, observedGeneration: .status.observedGeneration, unavailableReplicas: .status.unavailableReplicas, updatedReplicas: .status.updatedReplicas}' $name-deploy.json
       #jq '{generation: .metadata.generation, observedGeneration: .status.observedGeneration, status: .status }' $name-deploy.json
        exit 0
        ;;
esac

test -f counter || echo 0 > counter
counter=$(cat counter)
echo $((counter+1)) > counter

if ! [ -f $name-pids ]; then

    kubectl get events --watch --watch-only | ts > $name-events.log &
    kubectl get deploy $name --watch -o json | jq --unbuffered '. + {ts: now}' > $name-deploy.json &

    jobs -p > $name-pids
    disown %1 %2

fi

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
        image: minikube:5000/terminator
        env:
          - name: TERM_SLEEP
            value: "${term_sleep}"
          - name: COUNTER
            value: "${counter}"
EOF

kubectl rollout status deploy $name

echo watches still running, finish them with $0 --report
