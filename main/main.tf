terraform {
  backend "s3" {
    bucket         = "lambda-apigatewayateway-terraform-state"
    key            = "es2/remote_state/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform_state_aws"
  }
}

module "lambda" {
  source                    = "../API"
  
  region                    = "eu-west-3"
  source_file               = "../API/lambdaCode.py"
  output_path               = "../API/lambdaCode.zip"
  handler                   = "lambdaCode.lambda_handler" 
  runtime                   = "python3.8" 
  protocol_type             = "HTTP"
  auto_deploy               = true
  integration_type          = "AWS_PROXY"
  integration_method        = "POST"
  route_key                 = "GET /get"
  statement_id              = "AllowExecutionFromAPIGateway"
  action                    = "lambda:InvokeFunction"
  principal                 = "apigateway.amazonaws.com"
}

module "vpc" {
  source                   = "../API"

  name                     = "Lambda"
  vpc_cidr_block           = "10.0.0.0/16"
  instance_tenancy         = "default"
  public_subnet_cidr_block = "10.0.1.0/24"
}