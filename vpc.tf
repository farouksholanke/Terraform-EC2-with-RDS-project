resource "aws_vpc" "AppVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "AppVPC"
  }
}

##create subnets 

resource "aws_subnet" "AppSubnet1" {
  vpc_id            = aws_vpc.AppVPC.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "AppSubnet1"
  }
}

resource "aws_subnet" "AppSubnet2" {
  vpc_id            = aws_vpc.AppVPC.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "AppSubnet2"
  }
}
