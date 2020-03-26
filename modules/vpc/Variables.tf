variable "cidr-block" {
    description = "cidr_block range for the VPC"
    default = "10.0.0.0/16"
}

variable "public-subnet1-cidr" {
  description = "cidr-block for public subnet1"
  default = "10.0.0.0/24"
}

variable "public-subnet2-cidr" {
  description = "cidr-block for public subnet2"
  default = "10.0.1.0/24"
}

variable "private-subnet1-cidr" {
  description = "cidr-block for private subnet1"
  default = "10.0.2.0/24"
}

variable "private-subnet2-cidr" {
  description = "cidr-block for private subnet2"
  default = "10.0.3.0/24"
}

variable "min_size" {
  description = "Minimum size"
  default = 1
}

variable "max_size" {
  description = "Maximum size"
  default = 2
}

variable "image-id" {
  description = "ami id "
  default = "ami-0a887e401f7654935"
}

variable "instance-type" {
  description = "instance type "
  default = "t2.micro"
}

variable "key-name" {
  description = "Key file"
  default = "MYUSEA1"
}

variable "platform" {
  default = "Onica"
}

variable "env" {
  description = "Default Environment"
  default = "dev"
}

variable "OwnerContact" {
  description = "Default Owner Contact"
  default = "nagasravani.kollipara@gmail.com"
}

