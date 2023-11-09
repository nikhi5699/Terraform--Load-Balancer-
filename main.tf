#Launching a VPC
resource "aws_vpc" "main" {
  cidr_block = var.cidr
  tags = {
    Name="vpc-1"
  }
}
#Launching 2 Subnet's
resource "aws_subnet" "subnet1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch=true #Will attach a  public ip to instances launched inside that subnet, default value is False.
    tags = {
    Name="subnet-1"
  }
    
    
}
resource "aws_subnet" "subnet2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch=true #Will attach a  public ip to instances launched inside that subnet, default value is False.
  tags = {
    Name="subnet-2"
  }
}
#Launching Internet Gateway
resource "aws_internet_gateway" "itgw" {
    vpc_id = aws_vpc.main.id
    tags = {
    Name="igw-1"
  }
}
#Launching Route Table
resource "aws_route_table" "rt1" {
vpc_id = aws_vpc.main.id
route {
    cidr_block="0.0.0.0/0"
    gateway_id=aws_internet_gateway.itgw.id
    
}
tags ={
        Name="RT-1"
    }
  
}
#Launching RT associations
resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.subnet1.id
    route_table_id = aws_route_table.rt1.id
  
  
}
resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.subnet2.id
    route_table_id = aws_route_table.rt1.id
  
}
#Craeting a SG which allows HTTP and SSH traffic from Internet
resource "aws_security_group" "sg1" {
  name        = "allow_tls"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP to the instance"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
   ingress {
    description      = "SSH to the instance"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "HTTP-SSH"
  }
}
resource "aws_s3_bucket" "example" {
  bucket = "a-unique-s3bucket-for-terraform"

}

#Launching Instances 
resource "aws_instance" "instance1" {
    ami = "ami-0fc5d935ebf8bc3bc"
    instance_type ="t2.micro"
    #security_groups = [ "aws_security_group.sg1.id" ]
    vpc_security_group_ids = [aws_security_group.sg1.id]
    subnet_id = aws_subnet.subnet1.id
    user_data = base64encode(file("userdata.sh"))
    tags = {
      Name="Instance-1"
    }

}
resource "aws_instance" "instance2" {
    ami = "ami-0fc5d935ebf8bc3bc"
    instance_type ="t2.micro"
    vpc_security_group_ids = [aws_security_group.sg1.id]
    subnet_id = aws_subnet.subnet2.id
    user_data = base64encode(file("userdata1.sh"))
    tags = {
      Name="Instance-2"
    }
}
#Creating an Application LB
resource "aws_lb" "lb-1" {
  name               = "lb-1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg1.id]
  subnets            = [aws_subnet.subnet1.id,aws_subnet.subnet2.id]

  enable_deletion_protection = true


}
#Creating a Target-Group
resource "aws_lb_target_group" "tg1" {
    name = "tg1"
    port = 80
    vpc_id = aws_vpc.main.id
    protocol = "HTTP"
    health_check {
        path = "/"
        port="traffic-port"
    }
  
}

resource "aws_lb_target_group_attachment" "tg-attach" {
     target_group_arn = aws_lb_target_group.tg1.arn
     target_id = aws_instance.instance1.id
     port  =80
}
resource "aws_lb_target_group_attachment" "tg-attach2" {
   target_group_arn = aws_lb_target_group.tg1.arn
     target_id = aws_instance.instance2.id
     port  =80
}
#Creating a Listener 
resource "aws_lb_listener" "listner" {
    load_balancer_arn = aws_lb.lb-1.arn
    port =80
    protocol = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.tg1.arn
    type             = "forward"
  }
}
