provider "aws" {
  region = var.region
}

//VPC
resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = var.instance_tenancy

  tags = {
    Name = var.name
  }
}

resource "aws_internet_gateway" "IGW" {    
  vpc_id =  aws_vpc.vpc.id               
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidr_block

  tags = {
    Name = var.name
  }
}

resource "aws_route_table" "PublicRT" {
  vpc_id =  aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"               
    gateway_id = aws_internet_gateway.IGW.id
  }
}

resource "aws_route_table_association" "PublicRTassociation" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.PublicRT.id
}

resource "aws_default_security_group" "default_security_group" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//Lambda
data "archive_file" "zip" {
  type        = "zip"
  source_file = var.source_file
  output_path = var.output_path
}

data "aws_iam_policy_document" "policy" {
  statement {
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = [ "sts:AssumeRole" ]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = "${data.aws_iam_policy_document.policy.json}"
}

resource "aws_lambda_function" "lambda" {
  function_name = "lambdaCode"
  filename      = "${data.archive_file.zip.output_path}"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = var.handler
  runtime       = var.runtime

  vpc_config {
    subnet_ids         = [aws_subnet.public_subnet.id]
    security_group_ids = [aws_default_security_group.default_security_group.id]
  }
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
//API Gateway
resource "aws_apigatewayv2_api" "lambda" {
  name          = "lambdaAPI"
  protocol_type = var.protocol_type
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id      = aws_apigatewayv2_api.lambda.id
  name        = "lambdaAPI_stage"
  auto_deploy = var.auto_deploy
}

resource "aws_apigatewayv2_integration" "lambdaCode" {
  api_id             = aws_apigatewayv2_api.lambda.id
  integration_uri    =  aws_lambda_function.lambda.invoke_arn
  integration_type   = var.integration_type
  integration_method = var.integration_method
}

resource "aws_apigatewayv2_route" "lambdaCode" {
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = var.route_key
  target    = "integrations/${aws_apigatewayv2_integration.lambdaCode.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = var.statement_id
  action        = var.action
  function_name = aws_lambda_function.lambda.function_name
  principal     = var.principal
  source_arn    = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}