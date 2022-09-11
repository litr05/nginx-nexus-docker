#!/bin/bash


cd ../nginx/

# Docker build nginx image
podman build --no-cache -t nginx-nexus .
