module "api" {
  source     = "genstackio/apigateway2-api/aws"
  version    = "0.2.0"
  name       = var.name
  lambda_arn = module.lambda.arn
}

module "api-custom-domain" {
  source    = "genstackio/apigateway2-api/aws//modules/domain"
  version   = "0.2.0"
  api       = module.api.id
  stage     = module.api.stage
  dns       = var.dns
  zone      = var.dns_zone
  providers = {
    aws = aws
    aws.acm = aws.acm
  }
}

module "lambda" {
  source            = "genstackio/lambda/aws"
  version           = "0.3.0"
  s3_bucket         = var.package_s3_bucket
  s3_key            = var.package_s3_key
  file              = var.package_file
  name              = var.name
  handler           = var.handler
  timeout           = var.timeout
  memory_size       = var.memory_size
  policy_statements = var.tracing_mode == "Active" ? concat(var.lambda_policy_statements,[
     {
      actions   = ["xray:PutTraceSegments"]
      resources = ["*"]
      effect    = "Allow"
    },
    {
      actions   = ["xray:PutTelemetryRecords"]
      resources = ["*"]
      effect    = "Allow"
    }
  ]) : var.lambda_policy_statements
  tracing_mode      = var.tracing_mode
  variables         = var.variables
  runtime           = var.runtime
}
