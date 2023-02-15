#!/bin/bash

set -xeu

#Referencias:
#https://www.digitalocean.com/community/tutorials/how-to-automate-jenkins-setup-with-docker-and-jenkins-configuration-as-code

#Establecer las variables de entorno en la sesión de construcción de la imagen. en el ejemplo actual ejecutar
source $(dirname $0)/set_environment_variables.sh

# build image
docker build \
-t jenkins/jenkinsalfa:latest \
--build-arg ARG_ARM_CLIENT_ID=$ARM_CLIENT_ID \
--build-arg ARG_ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET \
--build-arg ARG_ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID \
--build-arg ARG_ARM_TENANT_ID=$ARM_TENANT_ID \
--build-arg ARG_JENKINS_ADMIN_ID=$JENKINS_ADMIN_ID \
--build-arg ARG_JENKINS_ADMIN_PASSWORD=$JENKINS_ADMIN_PASSWORD \
--no-cache ../

#docker create --name jenkins-alfa -p 8080:8080 jenkinsalfa:latest
#docker start jenkins-alfa

#Commands AZ CLI

resourceGroup="grjenkinsalfa"
aciStorageAccountName="sajenkinsalfa"
location="westeurope"
acrName="acrjenkinsalfa"
aciName="jenkins-alfa"

az account set -s $ARM_SUBSCRIPTION_ID

az group create --l $location \
    -n $resourceGroup \
    --tags "Project=JenkinsAlfa"

az storage account create \
    -g $resourceGroup \
    -n $aciStorageAccountName \
    --location $location \
    --sku Standard_LRS

# Create the file share
#az storage share create \
#  --name $ACI_FILE_SHARE_NAME \
#  --account-name $aciStorageAccountName \
#  -o none 

# create acr
az acr create -n $acrName \
    -g $resourceGroup \
    --sku Standard \
    --admin-enabled

# get login server
acrLoginServer=$(az acr show --name $acrName --query loginServer -o tsv)

# re-tag jenkins image
docker tag jenkins/jenkinsalfa:latest "$acrLoginServer/jenkinsalfa:latest"

# get acr admin user
acrAdminUser=$(az acr credential show -n $acrName -g $resourceGroup --query username -o tsv)

# get acr admin password
acrAdminPassword=$(az acr credential show -n $acrName -g $resourceGroup --query passwords[0].value -o tsv)

# log into acr
az acr login --name $acrName

# push image to acr
echo "pushing the jenkins image to azure container registry"
docker push "$acrLoginServer/jenkinsalfa:latest"

# get aci storage account key
echo "getting aci storage account key"
aciStorageAccountKey=$(az storage account keys list --resource-group $resourceGroup --account-name $aciStorageAccountName --query "[0].value" --output tsv)

# deploy to aci
echo "deploying the jenkins image to azure container instances"
az container create --resource-group $resourceGroup \
    --name $aciName \
    --image "$acrLoginServer/jenkinsalfa:latest" \
    --cpu 1 --memory 5 \
    --registry-login-server $acrLoginServer \
    --registry-username $acrAdminUser \
    --registry-password $acrAdminPassword \
    --dns-name-label "$aciName-dns" \
    --ports 8080 5000 \
    --azure-file-volume-account-name $aciStorageAccountName \
    --azure-file-volume-account-key $aciStorageAccountKey 

    #--azure-file-volume-share-name $ACI_FILE_SHARE_NAME \
    #--azure-file-volume-mount-path /var/jenkins_home/

# get aci fdqn
aciFdqn=$(az container show --resource-group $resourceGroup --name $aciName --query ipAddress.fqdn -o tsv)

echo "Acceso al servidor: http://$aciFdqn:8080"
