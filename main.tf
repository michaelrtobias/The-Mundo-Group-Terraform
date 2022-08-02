terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.24.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "mundo"
}

resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}

module "lambdas" {
  source                                 = "./modules/lambda"
  aws_codestarconnections_connection_arn = aws_codestarconnections_connection.github.arn
  send_email_queue                       = module.sqs.send_email_queue
  send_email_ses_identity                = module.ses.send_email_ses_identity
}

module "CICD" {
  source                      = "./modules/CICD"
  github_connection_arn       = aws_codestarconnections_connection.github.arn
  southwestwatches_com_bucket = module.frontend.southwestwatches_com_bucket
}


module "api_gateway" {
  source                  = "./modules/apigateway"
  create_lead_invoke_arn  = module.lambdas.create_lead_invoke_arn
  upload_image_invoke_arn = module.lambdas.upload_image_invoke_arn
  create_lead_arn         = module.lambdas.create_lead_arn
  upload_image_arn        = module.lambdas.upload_image_arn
  create_lead_lambda      = module.lambdas.create_lead_lambda
  upload_image_lambda     = module.lambdas.upload_image_lambda
}

module "sqs" {
  source            = "./modules/sqs"
  send_email_lambda = module.lambdas.send_email_lambda
}

module "route53" {
  source                      = "./modules/route53"
  sww_cloudfront_distribution = module.frontend.sww_cloudfront_distribution
}

module "frontend" {
  source = "./modules/frontend"
}

module "ses" {
  source                = "./modules/ses"
  southwestwatches_zone = module.route53.southwestwatches_zone
}

module "cognito" {
  source                = "./modules/cognito"
  southwestwatches_zone = module.route53.southwestwatches_zone
}

module "dynamodb" {
  source = "./modules/dynamodb"
}
