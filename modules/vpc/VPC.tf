
 data "aws_availability_zones" "available" {

 }
#######  VPC  #######
resource "aws_vpc" "custom-vpc" {
   cidr_block           =  var.cidr-block
   enable_dns_hostnames =  true

   tags = {
    Name         = "${var.platform}-${var.env}-vpc"
    Env          = var.env
    OwnerContact = var.OwnerContact
  }
}
#########  IGW - Internet Gateway  ########
resource "aws_internet_gateway" "igw1" {
  vpc_id  =  aws_vpc.custom-vpc.id

  tags = {
    Name         = "${var.platform}-${var.env}-IGW"
    Env          = var.env
    OwnerContact = var.OwnerContact
  }
}
#########  Public Subnet1  ###########
resource "aws_subnet" "public-subnet1" {
  vpc_id     = aws_vpc.custom-vpc.id
  cidr_block = var.public-subnet1-cidr
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name         = "${var.platform}-${var.env}-publicsubnet1"
    Env          = var.env
    OwnerContact = var.OwnerContact
  }
}
##########  Public Subnet2  #########
resource "aws_subnet" "public-subnet2" {
  vpc_id     = aws_vpc.custom-vpc.id
  cidr_block = var.public-subnet2-cidr
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
   Name         = "${var.platform}-${var.env}-publicsubnet2"
    Env          = var.env
    OwnerContact = var.OwnerContact
  }
}
############  Private Subnet1  #######
resource "aws_subnet" "private-subnet1" {
  vpc_id     = aws_vpc.custom-vpc.id
  cidr_block = var.private-subnet1-cidr
  
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name         = "${var.platform}-${var.env}-privatesubnet1"
    Env          = var.env
    OwnerContact = var.OwnerContact
  }
}
#########  Private Subnet2   #######
resource "aws_subnet" "private-subnet2" {
  vpc_id     = aws_vpc.custom-vpc.id
  cidr_block = var.private-subnet2-cidr
  
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name         = "${var.platform}-${var.env}-privatesubnet2"
    Env          = var.env
    OwnerContact = var.OwnerContact
  }
}
##########   EIP - Elastic IP  ##########
resource "aws_eip" "nat" {
  vpc = true
}
##########  NGW - NAT Gateway  ############
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-subnet1.id

  tags = {
    Name         = "${var.platform}-${var.env}-ngw"
    Env          = var.env
    
  }
}
########  Public RT  ########
resource "aws_route_table" "public-rt" {
   vpc_id = aws_vpc.custom-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }
  tags = {
    Name         = "${var.platform}-${var.env}-publicrt"
    Env          = var.env
    
  }
} 
#########  Public1 RTAssociation  ######
resource "aws_route_table_association" "a-public1" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.public-rt.id
}
#######  Public2 RTAssociation  #########
resource "aws_route_table_association" "b-public2" {
  subnet_id      = aws_subnet.public-subnet2.id
  route_table_id = aws_route_table.public-rt.id
}
##########  Private RT  ########
resource "aws_route_table" "private-rt" {
   vpc_id = aws_vpc.custom-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name         = "${var.platform}-${var.env}-privatert"
    Env          = var.env
    
  }
}
#######  Private1 RTAssociation  #####
resource "aws_route_table_association" "a-private1" {
  subnet_id      = aws_subnet.private-subnet1.id
  route_table_id = aws_route_table.private-rt.id
}
########  Private2 RTAssociation #####
resource "aws_route_table_association" "b-private2" {
  subnet_id      = aws_subnet.private-subnet2.id
  route_table_id = aws_route_table.private-rt.id
}















