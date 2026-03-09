################################################################################
# Public Subnets
################################################################################

resource "aws_subnet" "public" {
  count = var.public_subnet_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, var.public_subnet_newbits, var.public_subnet_offset + count.index)
  availability_zone       = local.azs[count.index % length(local.azs)]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.common_tags, var.public_subnet_tags, {
    Name = "${var.vpc_name}-public-${local.azs[count.index % length(local.azs)]}"
    Tier = "public"
  })
}

################################################################################
# Private Subnets
################################################################################

resource "aws_subnet" "private" {
  count = var.private_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, var.private_subnet_newbits, var.private_subnet_offset + count.index)
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(local.common_tags, var.private_subnet_tags, {
    Name = "${var.vpc_name}-private-${local.azs[count.index % length(local.azs)]}"
    Tier = "private"
  })
}
