module "apprunner" {
  source = "../../modules/apprunner"

  environment  = "dev"
  service_name = var.service_name
  image_uri    = var.image_uri
  cpu          = var.cpu
  memory       = var.memory

  runtime_environment_variables = {
    APP_ENV          = "dev"
    NODE_ENV         = "development"
    EXTERNAL_API_URL = var.external_api_url
  }

  tags = {
    CostTier = "dev"
  }
}
