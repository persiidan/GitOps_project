#!/bin/bash
# deployment/k8s/deploy.sh

# Default values
DOCKER_REGISTRY="idanpersi"
IMAGE_TAG="latest"
SERVICE_TYPE=""
PORT=""
ENV="dev"  # Default to dev environment

# Help function
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --app NAME                  Application name (required: 'backend' or 'frontend')"
    echo "  --env ENV                   Environment (dev/prod, default: dev)"
    echo "  --port PORT                 container port (default 5000 for backend , 80 for frontend)"
    echo "  --image NAME                Docker image name (required)"
    echo "  --registry URL              Docker registry URL"
    echo "  --tag TAG                   Image tag (default: latest)"
    echo "  --type TYPE                 Service type ( ClusterIP (default for backend)/LoadBalancer (default for frontend) )"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --app)
            APP_NAME="$2"
            shift 2
            ;;
        --env)
            ENV="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --image)
            DOCKER_IMAGE="$2"
            shift 2
            ;;
        --registry)
            DOCKER_REGISTRY="$2"
            shift 2
            ;;
        --tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --type)
            SERVICE_TYPE="$2"
            shift 2
            ;;
        --help)
            show_help
            ;;
        *)
            echo "Unknown parameter: $1"
            show_help
            ;;
    esac
done

# Validate required parameters
if [ -z "$APP_NAME" ] || [ -z "$DOCKER_IMAGE" ]; then
    echo "Error: Missing required parameters"
    show_help
fi

# Validate environment
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Error: Environment must be 'dev' or 'prod'"
    exit 1
fi

# Ensure app is either backend or frontend
if [ "$APP_NAME" != "backend" ] && [ "$APP_NAME" != "frontend" ]; then
    echo "Error: --app must be 'backend' or 'frontend'"
    exit 1
fi

# Set default ports if not provided
if [ -z "$PORT" ]; then
    if [ "$APP_NAME" == "frontend" ]; then
        PORT=80
    elif [ "$APP_NAME" == "backend" ]; then
        PORT=5000
    fi
fi

if [ -z "$SERVICE_TYPE" ]; then
    if [ "$APP_NAME" == "frontend" ]; then
        SERVICE_TYPE="LoadBalancer"
    else
        SERVICE_TYPE="ClusterIP"
    fi
fi

# Export variables for kustomize
export APP_NAME PORT DOCKER_REGISTRY DOCKER_IMAGE IMAGE_TAG SERVICE_TYPE ENV

# Apply processed files
echo "Applying Kubernetes configurations..."
kubectl kustomize deployment/k8s/$ENV | envsubst | kubectl apply -n gitops-project-$ENV -f -

# creating mongo db if not created
kubectl apply -n gitops-project-$ENV -f deployment/k8s/base/mongodb-secret.yaml
kubectl apply -n gitops-project-$ENV -f deployment/k8s/base/mongodb.yaml

echo "Deployment complete. Checking status..."
kubectl get all -n gitops-project-$ENV 