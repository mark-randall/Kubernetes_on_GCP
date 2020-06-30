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
        deploymentmanager.googleapis.com \
        stackdriver.googleapis.com
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
       --properties region:us-central1,zone:us-central1-a,initialNodeCount:3,db-user-password:$DATABASE_USER_PASSWORD

    # Service Account Key secret
    # TODO: Maping GCP SA to K8S SA (GCP perferred method)
    gcloud iam service-accounts keys create ~/key.json \
        --iam-account $DEPLOYMENT_NAME@$PROJECT_ID.iam.gserviceaccount.com
    kubectl create secret generic $DEPLOYMENT_NAME-sa-key \
        --from-file=service_account.json=~/key.json
    rm ~/key.json

    # Create DB connection url secret
    kubectl create secret generic cloudsql-db-credentials \
        --from-literal=databaseurl=postgres://$DEPLOYMENT_NAME:$DATABASE_USER_PASSWORD@127.0.0.1:5432/$DEPLOYMENT_NAME
}

# Build
# 
# Services:
# 1. Events API
#,_SQL_INSTANCE_NAME=${DEPLOYMENT_NAME}-sql,_REGION=us-central1" 
build() 
{
    # Build event_api
    gcloud builds submit \
        --config events_api_service/cloud_build/cloud_build.yaml \
        --substitutions "_SERVICE_NAME=${DEPLOYMENT_NAME},_SERVICE_VERSION=v8" \
        events_api_service
}

# Deploy to GKE cluster
#
# Apply:
# 1. Ngnix Ingress Controller
# 2. Deployment
# 3. Service for Deployment
# 3. Ingress for Service(s)
# SEE: Helm chart for details
deploy() 
{
    gcloud container clusters get-credentials $DEPLOYMENT_NAME --zone us-central1-a --project events-281416

    # TODO: Explore a better way to use nginx-ingress
    # Helm Stable doesn't work properlhy with my chart
    # helm repo add stable https://kubernetes-charts.storage.googleapis.com
    # helm install stable/nginx-ingress --generate-name
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud/deploy.yaml

    helm install $DEPLOYMENT_NAME ./helm \
        --set project=$PROJECT_ID \
        --set name=$DEPLOYMENT_NAME \
        --set apiVersion=v8
}

upgrade() {

    helm upgrade $DEPLOYMENT_NAME ./helm \
        --set project=$PROJECT_ID \
        --set name=$DEPLOYMENT_NAME \
        --set apiVersion=v8
} 

cleanup() {

    # Clean up between development to avoid GCP charges
    gcloud deployment-manager deployments delete $DEPLOYMENT_NAME
}