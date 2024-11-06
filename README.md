
🚀 Deploying Secure EC2 Instances with a Shared RDS Database

In this project, I will walk you through the process of deploying secure EC2 instances connected to a shared database on AWS using Terraform. I will cover the setup of a Virtual Private Cloud (VPC), Elastic Compute Cloud (EC2) instances, and a Relational Database Service (RDS) instance. My focus will be on adhering to best practices for security, scalability, and maintainability.

![image](https://github.com/user-attachments/assets/09dd10db-dedd-4fec-a366-885ef70d2dae)


## Why Terraform

Why Terraform?

•	Immutable Infrastructure: Terraform encourages the creation of immutable infrastructure through declarative configuration files. This means your infrastructure can be versioned and treated as you would with application code.

•	Idempotency: Terraform ensures that running the same configuration multiple times results in the same state, avoiding manual errors and inconsistencies.

•	Scalability: With Terraform, scaling your infrastructure up or down becomes a matter of changing a few lines in your configuration file.

Terraform is an open-source infrastructure as code software tool that allows you to define and provision a cloud infrastructure using a high-level configuration language. It supports various cloud providers, including AWS, which i will be using for my project.
## Setting up your AWS Environment with Terraform 
🧮 Setting Up Your AWS Environment with Terraform
Before diving into the specifics, ensure you have Terraform and AWS CLI installed and configured on your machine.

. In my project directory, I created a provider.tf file that contained the configuration of my AWS provider
```
provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```

## Building the Infrastructure
🧱 Building the Infrastructure
My web application will need a VPC, EC2 instances, and an RDS instance. I will define each of these components in various .tf files.

Virtual Private Cloud (VPC)

A VPC is a virtual network dedicated to your AWS account. It is isolated from other virtual networks in the AWS cloud. I created a VPC with dns support and dns hostnames enabled

```
resource "aws_vpc" "AppVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "AppVPC"
  }
}
```
SUBNETS

Within the VPC, I created subnets. Each subnet resides in a different availability zone for high availability.
```
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
```
SECURITY GROUPS

Security groups act as a virtual firewall for your instances to control inbound and outbound traffic. The security group allows inbound traffic from port 22, 80 , 443 and 3306
and outbound traffic to anywhere 
```
resource "aws_security_group" "WebTrafficSG" {
  vpc_id = aws_vpc.AppVPC.id
  name   = "WebTrafficSG"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebTrafficSG"
  }
}
```
NETWORK INTERFACES

I created two network interfaces; nw-interface1 and nw-interface2. Both of the interfaces would use WebTrafficSG as the security group, while the nw-interface1 would use AppSubnet1 and nw-interface2 use AppSubnet2 respectively.
```
resource "aws_network_interface" "nw-interface1" {
  subnet_id = aws_subnet.AppSubnet1.id
  security_groups = [aws_security_group.WebTrafficSG.id]
  tags = {
    Name        = "nw-interface1"
  }  
}

resource "aws_network_interface" "nw-interface2" {
  subnet_id = aws_subnet.AppSubnet2.id
  security_groups = [aws_security_group.WebTrafficSG.id]
  tags = {
    Name        = "nw-interface2"
  }  
}
```
INTERNET GATEWAY & ROUTE TABLE 

I attached the network (AppVPC) to an Internet Gateway named AppInternetGateway.
Also, I created a route table for the VPC AppVPC, named  AppRouteTable. I created a route in my AWS infrastructure to allow internet access. The route is associated with the route table named AppRouteTable and would direct traffic to the internet gateway named AppInternetGateway. Furthermore, I associated two subnets, AppSubnet1 and AppSubnet2, with the route table named AppRouteTable to ensure that the subnets use this route table for their traffic routing.
```
# create internet gateway and route table
resource "aws_internet_gateway" "AppIGW" {
  vpc_id = aws_vpc.AppVPC.id

  tags = {
    Name = "AppInternetGateway"
  }
}

resource "aws_route_table" "AppRouteTable" {
  vpc_id = aws_vpc.AppVPC.id
  tags = {
    Name = "AppRouteTable"
  }
}

output "route_table_ID" {
  value = aws_route_table.AppRouteTable.id
}

## create out 
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.AppRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.AppIGW.id
}

## associate route table

resource "aws_route_table_association" "AppSubnet1_association" {
  subnet_id      = aws_subnet.AppSubnet1.id
  route_table_id = aws_route_table.AppRouteTable.id
}

resource "aws_route_table_association" "AppSubnet2_association" {
  subnet_id      = aws_subnet.AppSubnet2.id
  route_table_id = aws_route_table.AppRouteTable.id
}
```

Elastic Compute Cloud (EC2)

EC2 instances will host our web application. I created an instance within my VPC and associated it with the security group I defined; one in each subnet (AppSubnet1 and AppSubnet2), using the ami-06c68f701d8090592 AMI and t2.micro instance type. To ensure that the EC2 instances get assigned a public IP address, I created two Elastic IP (EIP) resources and attached them to one network interface each - nw-interface1 andnw-interface2 .
```
resource "aws_eip" "public_ip1" {
  vpc = true
  network_interface = aws_network_interface.nw-interface1.id
}

resource "aws_eip" "public_ip2" {
  vpc = true
  network_interface = aws_network_interface.nw-interface2.id
}
```
```
resource "aws_instance" "WebServer1" {
  ami             = "ami-06c68f701d8090592"
  instance_type   = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.nw-interface1.id
    device_index = 0
  }

  key_name = "my-ec2-key"

  tags = {
    Name = "WebServer1"
  }
}

resource "aws_instance" "WebServer2" {
  ami             = "ami-06c68f701d8090592"
  instance_type   = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.nw-interface2.id
    device_index = 0
  }

  key_name = "my-ec2-key"

  tags = {
    Name = "WebServer2"
  }
}

output "instance1_id" {
  value = aws_instance.WebServer1.id
}

output "instance2_id" {
  value = aws_instance.WebServer2.id
}
```
I created a key-pair for the EC2 instances called my-ec2-key. stored it in /root.
```
aws ec2 create-key-pair --key-name my-ec2-key --query 'KeyMaterial' --output text > /root/my-ec2-key.pem
```
RDS INSTANCE

I created a database subnet group called app-db-subnet-group which includes the subnets within the VPC AppVPC and provisioned an RDS instance in AppVPC. The database should be accessible from the WebServer security group and has the following specs:
```
# create rds subnet 
resource "aws_db_subnet_group" "app_db_subnet_group" {
  name       = "app-db-subnet-group"
  subnet_ids = [aws_subnet.AppSubnet1.id, aws_subnet.AppSubnet2.id]

  tags = {
    Name = "AppDBSubnetGroup"
  }
}

## create rds instance

resource "aws_db_instance" "app_database" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.33"  
  instance_class       = "db.t3.micro" 
  identifier           = "appdatabase"
  db_name              = "appdatabase"
  username             = var.rds_username
  password             = var.rds_pass 
  publicly_accessible     = true
  db_subnet_group_name = aws_db_subnet_group.app_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.WebTrafficSG.id]

  tags = {
    Name = "AppDatabase"
  }
}
```
After deploying the infrastructure, I ssh into one of the EC2 instances 
![image](https://github.com/user-attachments/assets/f548eaec-fd22-453f-9a6c-61d918f616d8)


Since, my AMI instance doesn't have MySQL pre-installed, I ran the following commands sequentially to install it:
```
sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm

sudo dnf install mysql80-community-release-el9-1.noarch.rpm -y

sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023

sudo dnf install mysql-community-client -y
```
Once MySQL is installed, run the following command to connect to the database:
mysql -h <DB_endpoint> -P 3306 -u admin -p
Replace the <DB_endpoint> with the endpoint of your database instance that was created.
When prompted for password, enter the password you created via terraform.

Once connected, I run mysql; SHOW DATABASES; and I can see that my infrastrcture was configured properly and my database is running
![image](https://github.com/user-attachments/assets/232d91ce-2745-42a4-b6d7-01740df28247)

![image](https://github.com/user-attachments/assets/402d372e-21d3-429a-af6b-8db45e78b111)



