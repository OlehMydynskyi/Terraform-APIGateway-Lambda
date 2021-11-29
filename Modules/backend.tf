terraform {
  backend "s3" {
    bucket         = "lambda-apigatewayateway-terraform-state"
    key            = "es2/remote_state/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform_state_aws"
  }
}