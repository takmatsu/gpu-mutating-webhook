# GPU Mutating Webhook

This webhook fixes [the problem](https://github.com/NVIDIA/k8s-device-plugin#running-gpu-jobs) that no GPU request container can see all GPUs.

## Prerequisites

Kubernetes 1.9.0 or above with the `admissionregistration.k8s.io/v1beta1` API enabled. Verify that by the following command:
```
kubectl api-versions | grep admissionregistration.k8s.io/v1beta1
```
The result should be:
```
admissionregistration.k8s.io/v1beta1
```

In addition, the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` admission controllers should be added and listed in the correct order in the admission-control flag of kube-apiserver.

## Build

1. Setup dep

   The repo uses [dep](https://github.com/golang/dep) as the dependency management tool for its Go codebase. Install `dep` by the following command:
```
go get -u github.com/golang/dep/cmd/dep
```

   
```
./build
```

## Deploy

1. Create namespace
```
kubectl apply -f deployment/namespace.yaml
```

2. Create a signed cert/key pair and store it in a Kubernetes `secret` that will be consumed by sidecar deployment
```
./deployment/webhook-create-signed-cert.sh \
    --service gpu-mutating-webhook-svc \
    --secret gpu-mutating-webhook-certs \
    --namespace gpu-mutating
```

3. Patch the `MutatingWebhookConfiguration` by set `caBundle` with correct value from Kubernetes cluster
```
cat deployment/mutatingwebhook.yaml | \
    deployment/webhook-patch-ca-bundle.sh > \
    deployment/mutatingwebhook-ca-bundle.yaml
```

4. Deploy resources
```
kubectl apply -f deployment/deployment.yaml
kubectl apply -f deployment/service.yaml
kubectl apply -f deployment/mutatingwebhook-ca-bundle.yaml
```

## Verify

1. The sidecar inject webhook should be running
```
# kubectl get pods -n gpu-mutating
NAME                                               READY     STATUS    RESTARTS   AGE
gpu-mutating-webhook-deployment-7f55d45d64-mpkmk   1/1       Running   0          6m
# kubectl get deployment -n gpu-mutating
NAME                              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
gpu-mutating-webhook-deployment   1         1         1            1           7m
```

2. Deploy an app in Kubernetes cluster, take `sleep` app as an example
```
# cat <<EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: sleep
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: sleep
    spec:
      containers:
      - name: sleep
        image: tutum/curl
        command: ["/bin/sleep","infinity"]
        imagePullPolicy: 
EOF
```

4. Verify container env injected
```
# kubectl get pods
NAME                                                READY     STATUS      RESTARTS   AGE
sleep-854884fd47-98xq7                              1/1       Running     0          7m
# kubectl describe pod sleep-854884fd47-98xq7 | grep NVIDIA_VISIBLE_DEVICES
     NVIDIA_VISIBLE_DEVICES:  none
```

## LICENSE
This is created from [kube-mutating-webhook-tutorial](https://github.com/morvencao/kube-mutating-webhook-tutorial)
