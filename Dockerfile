FROM alpine:latest

ADD gpu-mutating-webhook /gpu-mutating-webhook
ENTRYPOINT ["./gpu-mutating-webhook"]
