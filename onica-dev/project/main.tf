provider "aws" {
  region = "us-east-1"
  
}

terraform{
    backend "s3"{
      bucket = "onica-venkata-kollipara"
      key    = "onica-venkata-kollipara/s3"
      region = "us-east-1"
    }
}

module "Onica-project" {
  source = "../../modules/vpc"
   cidr-block =  "10.0.0.0/16"
   public-subnet1-cidr =  "10.0.0.0/24"
   public-subnet2-cidr =  "10.0.1.0/24"
   private-subnet1-cidr =  "10.0.2.0/24"
   private-subnet2-cidr =  "10.0.3.0/24"
   min_size =  1
   max_size =  2
   image-id = "ami-0a887e401f7654935"
   instance-type =  "t2.micro"
   key-name = "onica"
   platform = "Onica"
   env  =  "dev"
   OwnerContact  =  "nagasravani.kollipara@gmail.com"
}
