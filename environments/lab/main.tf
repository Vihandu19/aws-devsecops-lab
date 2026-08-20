module "network" {
  source = "../../modules/network"

  vpc_cidr    = var.vpc_cidr
  name_prefix = local.name_prefix

  subnets = {
    public-a = {
      cidr_block        = "10.42.0.0/24"
      availability_zone = "ca-central-1a"
      type              = "public"
    }

    public-b = {
      cidr_block        = "10.42.1.0/24"
      availability_zone = "ca-central-1b"
      type              = "public"
    }

    private-a = {
      cidr_block        = "10.42.10.0/24"
      availability_zone = "ca-central-1a"
      type              = "private"
    }

    private-b = {
      cidr_block        = "10.42.11.0/24"
      availability_zone = "ca-central-1b"
      type              = "private"
    }
  }
}


module "compute" {
  source = "../../modules/compute"

  name_prefix                = local.name_prefix
  private_subnets            = module.network.private_subnets
  instance_security_group_id = module.network.instance_security_group_id
}


module "alb" {
  source = "../../modules/alb"

  name_prefix           = local.name_prefix
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.network.alb_security_group_id
  instance_ids          = module.compute.instance_ids
}
