module "apprunner" {
  source = "../../modules/apprunner"

  environment  = "prod"
  service_name = var.service_name
  image_uri    = var.image_uri
  cpu          = var.cpu
  memory       = var.memory

  runtime_environment_variables = {
    APP_ENV          = "prod"
    NODE_ENV         = "production"
    EXTERNAL_API_URL = var.external_api_url
  }

  tags = {
    CostTier = "prod"
  }
}
