module "lambda" {
  source                    = "../Lambda"
  
  source_file               = "./lambdaCode.py"
  output_path               = "./lambdaCode.zip"
  handler                   = "lambdaCode.lambda_handler" 
  runtime                   = "python3.8" 
  public_subnet_id          = module.networking.public_subnet_id
  default_security_group_id = module.networking.default_security_group_id
}

module "api" {
  source             = "../API"

  protocol_type      = "HTTP"
  auto_deploy        = true
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  route_key          = "GET /get"
  statement_id       = "AllowExecutionFromAPIGateway"
  action             = "lambda:InvokeFunction"
  principal          = "apigateway.amazonaws.com"
  lambda_function    = module.lambda.lambda_function
}

module "networking" {
  source                   = "../Networking"

  name                     = "Lambda"
  vpc_cidr_block           = "10.0.0.0/16"
  instance_tenancy         = "default"
  public_subnet_cidr_block = "10.0.1.0/24"
}