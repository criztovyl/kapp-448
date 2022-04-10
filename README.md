# Reproducer for kap not waiting for Deployments with Recreate strategy

[Deployment with strategy RECREATE doesn't wait for reconciliation during redeploy. (#448)](https://github.com/vmware-tanzu/carvel-kapp/issues/448)

this reproducer shows that when the Pods in a Recreate deployment do not
terminate fast enough, kapp simply returns instead of waiting.

## Setup minikube w/ podman and cri-o

```
minikube config set driver podman
minikube config set container-runtime crio

minikube start

# enable registry addon and add as insecure registry
minikube addons enable registry

# passing --insecure-registry to start does not work with podman driver
# https://github.com/kubernetes/minikube/issues/13932
minikube ssh "echo CRIO_CONFIG_OPTIONS='--insecure-registry minikube:5000' | sudo tee -a /etc/default/crio >/dev/null; sudo systemctl restart crio"

podman build -t terminator .
podman push --tls-verify=false terminator $(minikube ip):5000/terminator
```

## Reproduce!

With `test-termination-fast.sh` in most cases kapp properly waits correctly for
the deployment.

With `test-termination-slow.sh` kapp does not properly wait.

## Analyze

With `test-termination-*.sh --report` you can analyze the states the deployment went through.
