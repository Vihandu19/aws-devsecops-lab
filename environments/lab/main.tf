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