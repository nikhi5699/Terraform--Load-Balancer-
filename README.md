# Terraform--Load-Balancer-
Creating a Load balancer using Terraform

This repository consists of terraform files used to create a VPC,2 Subnets(both inside that VPC),2 instances(one in each subnet),an Application Load Balancer,Target Group which has 2 instances in it.

Configure your AWS account using "aws configure" 

Use following commands to execute the Terraform files-

1)terraform init -to initialize the plugins.

2)terraform plan -to check the list of resources which are going to be added. 

3)terraform apply- to apply changes and cxreate resources in your AWS console

4)terraform destroy- to destroy all the launched resources 


