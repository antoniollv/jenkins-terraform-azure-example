#!/bin/bash
# Azure Service Principal "azure-cli-2023-02-12-19-29-57"
export ARM_CLIENT_ID=245cc77e-cad9-494c-8901-7b95e363bb14
export ARM_CLIENT_SECRET=JT~8Q~VSiaglxV~ZBbEqNbz_NhGKmuufOqHRmbiq
export ARM_SUBSCRIPTION_ID=bc4a995c-a16a-41e3-ba61-5f5cf69b4d7f
export ARM_TENANT_ID=28f3c09e-f27e-4b1d-8f22-3cc5621fc4e0
# Jenkins credentials
export JENKINS_ADMIN_ID=admin
export JENKINS_ADMIN_PASSWORD=$(pwgen -sy 16 1)
echo "Password usuario Jenkins admin: $JENKINS_ADMIN_PASSWORD"
