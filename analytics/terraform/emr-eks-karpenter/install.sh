#!/bin/bash

# Get user input for AWS region
read -p "Enter the region: " region
export AWS_DEFAULT_REGION=$region

echo "This install script will install default add-ons" 
echo "You can see the list of default and optional modules on this website: https://awslabs.github.io/data-on-eks/docs/amazon-emr-on-eks/emr-eks-karpenter"

# Get user input to check whether they want to install optional modules
read -p "Do you want to install optional modules? [Y]es, [N]o, or [C]ustom: " install_optional

# Set the default values for optional modules 
enable_yunikorn=false
enable_fsx_for_lustre=false
enable_cloudwatch_metrics=false
enable_aws_for_fluentbit=false
echo "enable_yunikorn=false" >> custom.tfvars
echo "enable_fsx_for_lustre=false" >> custom.tfvars
echo "enable_cloudwatch_metrics=false" >> custom.tfvars
echo "enable_aws_for_fluentbit=false" >> custom.tfvars

# List of Terraform modules to apply in sequence
default_targets=(
  "module.vpc"
  "module.vpc_endpoints_sg"
  "module.vpc_endpoints"
  "module.eks"
  "module.ebs_csi_driver_irsa"
  "module.vpc_cni_irsa"
  "module.eks_blueprints_kubernetes_addons"
  "module.emr_containers"
)

# Check user input for optional modules
if [[ "$install_optional" =~ ^[Yy]$ ]]; then
  enable_yunikorn=true
  enable_fsx_for_lustre=true
  enable_cloudwatch_metrics=true
  enable_aws_for_fluentbit=true
  echo "editing custom.tfvars and changing all optional addons to true"
  sed -i '' 's/^enable_yunikorn.*/enable_yunikorn=true/' custom.tfvars
  sed -i '' 's/^enable_fsx_for_lustre.*/enable_fsx_for_lustre=true/' custom.tfvars
  sed -i '' 's/^enable_cloudwatch_metrics.*/enable_cloudwatch_metrics=true/' custom.tfvars
  sed -i '' 's/^enable_aws_for_fluentbit.*/enable_aws_for_fluentbit=true/' custom.tfvars
  elif [[ "$install_optional" =~ ^[Cc]$ ]]; then
    read -p "Do you want to install yunikorn module? [Y]es, [N]o: " select_yunikorn
    if [[ "$select_yunikorn" =~ ^[Yy]$ ]]; then 
      echo "enabling yunikorn"
      enable_yunikorn=true
      if grep -q '^enable_yunikorn=' custom.tfvars; then
        sed -i '' 's/^enable_yunikorn.*/enable_yunikorn=true/' custom.tfvars
      else
        echo "enable_yunikorn=true" >> custom.tfvars
      fi
    fi
    read -p "Do you want to install FSx for Lustre module? [Y]es, [N]o: " select_fsx_for_lustre
    if [[ "$select_fsx_for_lustre" =~ ^[Yy]$ ]]; then 
      echo "enabling FSx for Lustre"
      enable_fsx_for_lustre=true
      if grep -q '^enable_fsx_for_lustre=' custom.tfvars; then
        sed -i '' 's/^enable_fsx_for_lustre.*/enable_fsx_for_lustre=true/' custom.tfvars
      else
        echo "enable_fsx_for_lustre=true" >> custom.tfvars
      fi
    fi
    read -p "Do you want to install CloudWatch Container Insights module? [Y]es, [N]o: " select_cloudwatch_metrics
    if [[ "$select_cloudwatch_metrics" =~ ^[Yy]$ ]]; then 
      echo "enabling CloudWatch Container Insights"
      enable_cloudwatch_metrics=true
      if grep -q '^enable_cloudwatch_metricse=' custom.tfvars; then
        sed -i '' 's/^enable_cloudwatch_metrics.*/enable_cloudwatch_metrics=true/' custom.tfvars
      else
        echo "enable_cloudwatch_metrics=true" >> custom.tfvars
      fi      
    fi    
    read -p "Do you want to install AWS for FluentBit module? [Y]es, [N]o: " select_aws_for_fluent_bit
    if [[ "$select_aws_for_fluent_bit" =~ ^[Yy]$ ]]; then 
      echo "enabling AWS for FluentBit"
      enable_aws_for_fluentbit=true
      if grep -q '^enable_aws_for_fluentbit=' custom.tfvars; then
        sed -i '' 's/^enable_aws_for_fluentbit.*/enable_aws_for_fluentbit=true/' custom.tfvars
      else
        echo "enable_aws_for_fluentbit=true" >> custom.tfvars
      fi            
    fi        
fi

# # Apply modules in sequence
# for default_target in "${default_targets[@]}"
# do
#   echo "Initiallizing Terraform"
#   terraform init
#   echo "Applying module $default_target..."
#   terraform apply -target="$default_target" -auto-approve
#   apply_output=$(terraform apply -target="$default_target" -auto-approve 2>&1)
#   if [[ $? -eq 0 && $apply_output == *"Apply complete"* ]]; then
#     echo "SUCCESS: Terraform apply of $default_target completed successfully"
#   else
#     echo "FAILED: Terraform apply of $default_target failed"
#     exit 1
#   fi
# done

# Final apply to catch any remaining resources
echo "Applying any custom resources..."
terraform apply -auto-approve -var-file="custom.tfvars"
custom_apply_output=$(terraform apply -auto-approve -var-file="custom.tfvars" 2>&1)
if [[ $? -eq 0 && $custom_apply_output == *"Apply complete"* ]]; then
  echo "SUCCESS: Terraform apply of custom modules completed successfully"
else
  echo "FAILED: Terraform apply of custom modules failed"
  exit 1
fi
# echo "Applying remaining resources..."
# terraform apply -auto-approve
# apply_output=$(terraform apply -auto-approve 2>&1)
# if [[ $? -eq 0 && $apply_output == *"Apply complete"* ]]; then
#   echo "SUCCESS: Terraform apply of all modules completed successfully"
# else
#   echo "FAILED: Terraform apply of all modules failed"
#   exit 1
# fi
