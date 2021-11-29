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
    subnet_ids         = [var.public_subnet_id]
    security_group_ids = [var.default_security_group_id]
  }
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}