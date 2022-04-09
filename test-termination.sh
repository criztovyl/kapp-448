#!/usr/bin/env -S bash -ex

test -f counter || echo 0 > counter; counter=$(cat counter)

[ "$term_sleep" ] || term_sleep=0

name=termination-${term_sleep}

kapp deploy -a $name -f - --yes <<EOF
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

echo $((counter+1)) > counter
