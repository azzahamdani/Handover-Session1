#!/bin/bash

source ./utils.sh

# ---------------------------------------------------------------------------------------------------------------------
# Install Tools
# ---------------------------------------------------------------------------------------------------------------------

infoln "Install kubernetes tools"

sudo curl --silent --location -o /usr/local/bin/kubectl \
   https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl

sudo chmod +x /usr/local/bin/kubectl

infoln "Update awscli"

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

infoln "Install jq, envsubst (from GNU gettext utilities) and bash-completion"

sudo yum -y install jq gettext bash-completion moreutils

infoln "Install yq for yaml processing"

echo 'yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq "$@"
}' | tee -a ~/.bashrc && source ~/.bashrc

infoln "Verify the binaries are in the path and executable"

for command in kubectl jq envsubst aws
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done

infoln "Enable kubectl bash_completion"

kubectl completion bash >>  ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

infoln "Set the AWS Load Balancer Controller version"

echo 'export LBC_VERSION="v2.4.1"' >>  ~/.bash_profile
echo 'export LBC_CHART_VERSION="1.4.1"' >>  ~/.bash_profile
.  ~/.bash_profile

infoln "Install eksctl"

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

sudo mv -v /tmp/eksctl /usr/local/bin

infoln "Confirm the eksctl command works:"

eksctl version

infoln "Enable eksctl bash-completion"


eksctl completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

# ---------------------------------------------------------------------------------------------------------------------
# Udate IAM setting 
# ---------------------------------------------------------------------------------------------------------------------

infoln "Disable temporary credentials"

aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials

infoln "Configure CLI with the current Region "

export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text --region $AWS_REGION))

infoln "Check the desired resgion"

test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo AWS_REGION is not set

infoln "Save to the bash_profile"
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
echo "export AZS=(${AZS[@]})" | tee -a ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get default.region
source ~/.bash_profile

infoln "Validate IAM role"

aws sts get-caller-identity --query Arn | grep eksworkshop-admin -q && echo "IAM role valid" || echo "IAM role NOT valid"


# ---------------------------------------------------------------------------------------------------------------------
# CLONE THE SERVICE REPOS
# ---------------------------------------------------------------------------------------------------------------------

infoln "clone the services repos"

cd ~/environment
git clone [URLTOFARMTOPLATE]

