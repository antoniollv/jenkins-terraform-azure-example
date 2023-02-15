FROM jenkins/jenkins:2.390

# INSTALL AZURE & CLI TERRAFORM 
USER root
RUN apt-get update && \
    apt-get install -y apt-utils \
    -y curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest#install
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
# https://www.terraform.io/downloads.html
RUN curl https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip --output terraform.zip
# unzip terraform
RUN unzip terraform.zip
# move to usr/local/bin directory
RUN mv terraform usr/local/bin
# clean up
RUN rm terraform.zip    

# drop back to the regular jenkins user - good practice
USER jenkins

ARG ARG_ARM_CLIENT_ID \
    ARG_ARM_CLIENT_SECRET \
    ARG_ARM_SUBSCRIPTION_ID\
    ARG_ARM_TENANT_ID\
    ARG_JENKINS_ADMIN_ID \
    ARG_JENKINS_ADMIN_PASSWORD

# Set environment variables for azure cli & Jenkins CASC
ENV ARM_CLIENT_ID=$ARG_ARM_CLIENT_ID \
    ARM_CLIENT_SECRET=$ARG_ARM_CLIENT_SECRET \
    ARM_SUBSCRIPTION_ID=$ARG_ARM_SUBSCRIPTION_ID \
    ARM_TENANT_ID=$ARG_ARM_TENANT_ID\
    JENKINS_ADMIN_ID=$ARG_JENKINS_ADMIN_ID \
    JENKINS_ADMIN_PASSWORD=$ARG_JENKINS_ADMIN_PASSWORD \
    JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
    CASC_JENKINS_CONFIG="/var/jenkins_home/casc.yaml"

# Install Jenkins plugins
RUN jenkins-plugin-cli --plugins \
    azure-credentials:252.vd40e833b_3206 \
    azure-keyvault:161.va_60991a_5d3d2 \
    configuration-as-code:1569.vb_72405b_80249 \
    workflow-aggregator:590.v6a_d052e5a_a_b_5
#    terraform:1.0.10

# File witch Jenkins CASC definition
COPY --chown=jenkins:jenkins casc.yaml /var/jenkins_home/casc.yaml