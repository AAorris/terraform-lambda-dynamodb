# Terraform Lambda DynamoDB

API Gateway to Lambda to DynamoDB using Terraform.

## Quickstart

Follow Terraform's getting started documentation

https://learn.hashicorp.com/collections/terraform/aws-get-started

You should now:

- Have Terraform installed
- Know how to init and apply with terraform

Read through main.tf until the following is clear:

- Your AWS region is correct
- `index.js` is turned into a lambda function
- An API gateway is linked to the lambda function
- A DynamoDB table is created
- The lambda function is given access to DynamoDB

`terraform apply`

Clean up when you're done testing

`terraform destroy`
