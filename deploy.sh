#!/bin/bash

# Deployment requires the following steps
# 1. Create GCP project with billing enable with console
# 2. Enable services on project with gcloud
# 3. Create infastructure with Deployment Manager
# 4. Build and upload contains with Cloud Build
# 5. Apply pods, deployment, and services to cluster with gcloud

# Enable all necessary GCP services / apis
enable_services()
{
    gcloud services enable \
        iam.googleapis.com \
        compute.googleapis.com \
        container.googleapis.com \
        sqladmin.googleapis.com \
        sql-component.googleapis.com \
        sqladmin.googleapis.com \
        cloudbuild.googleapis.com \
        cloudresourcemanager.googleapis.com \
        secretmanager.googleapis.com \
        deploymentmanager.googleapis.com

}

# Create infastructure 
# 1. GKE K8 cluster
# 2. Cloud SQL DBs for individual services
# 3. SecretManager secrets for SQL DB URLs
create_infastructure()
{
    # Use GCP Deployment Manager to create infastructure for project
    # SEE: template.jinja 
    gcloud deployment-manager deployments update $DEPLOYMENT_NAME \
        --template deployment_manager/template.jinja \
        --properties zone:us-central1-a,initialNodeCount:1
}

# Build
# 
# Services:
# 1. Events API
build() 
{
    # Build event_api
    gcloud builds submit \
        --config events_api_service/cloud_build/cloud_build.yaml \
        --substitutions "_SERVICE_NAME=${DEPLOYMENT_NAME},_SERVICE_VERSION=v2" \
        events_api_service
}

# Deploy to GKE cluster
#
# Apply:
# 1. Deployment
# 2. Service
deploy() 
{

    gcloud container clusters get-credentials events --zone us-central1-a --project events-281416

    # Apply nginx ingress controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud/deploy.yaml

    # Apply deployment and service
    kubectl apply --force -f manifests/manifest.yaml
}