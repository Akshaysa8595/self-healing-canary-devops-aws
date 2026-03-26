provider "aws" {
  region = "us-east-1"
}

# ---------------- VPC ----------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# ---------------- SUBNETS ----------------
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "main_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet-2"
  }
}

# ---------------- INTERNET ----------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.main_2.id
  route_table_id = aws_route_table.rt.id
}

# ---------------- SECURITY ----------------
resource "aws_security_group" "sg" {
  name   = "allow_http_ssh"
  vpc_id = aws_vpc.main.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- AMI ----------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ---------------- EC2 V1 ----------------
resource "aws_instance" "app_v1" {
  count = 2

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  subnet_id = element([
    aws_subnet.main.id,
    aws_subnet.main_2.id
  ], count.index)

  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from V1 - $(hostname)" > /var/www/html/index.html
              EOF

  tags = {
    Name = "app-v1-${count.index}"
  }
}

# ---------------- EC2 V2 ----------------
resource "aws_instance" "app_v2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  subnet_id                   = aws_subnet.main_2.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from V2 🚀" > /var/www/html/index.html
              EOF

  tags = {
    Name = "app-v2"
  }
}

# ---------------- TARGET GROUPS ----------------
resource "aws_lb_target_group" "v1" {
  name     = "app-tg-v1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path     = "/"
    matcher  = "200"
    interval = 30
  }
}

resource "aws_lb_target_group" "v2" {
  name     = "app-tg-v2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path     = "/"
    matcher  = "200"
    interval = 30
  }
}

# ---------------- ATTACHMENTS ----------------
resource "aws_lb_target_group_attachment" "v1_attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.v1.arn
  target_id        = aws_instance.app_v1[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "v2_attach" {
  target_group_arn = aws_lb_target_group.v2.arn
  target_id        = aws_instance.app_v2.id
  port             = 80
}

# ---------------- ALB ----------------
resource "aws_lb" "alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.main.id,
    aws_subnet.main_2.id
  ]

  security_groups = [aws_security_group.sg.id]
}

# ---------------- LISTENER (CANARY) ----------------
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.v1.arn
        weight = 90
      }

      target_group {
        arn    = aws_lb_target_group.v2.arn
        weight = 10
      }
    }
  }
}

# ---------------- OUTPUT ----------------
output "alb_dns" {
  value = aws_lb.alb.dns_name
}