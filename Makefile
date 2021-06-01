
# Image URL to use all building/pushing image targets
IMG ?= pod-gateway:latest

# Build the docker image
docker-build:
	docker build . -t ${IMG}

# Push the docker image
docker-push:
	docker push ${IMG}