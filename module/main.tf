resource "aws_security_group" "module_Sg" {

  name=var.sgname
  vpc_id = aws_vpc.module_vpc.id

  ingress {

    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = var.block1
  }

ingress {

  from_port =22
  to_port = 22
  protocol = "TCP"
  cidr_blocks = var.block1
}

  egress {

    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = var.block1
  }

}

resource "aws_vpc" "module_vpc" {

  cidr_block = var.block2

  tags = {

    Name= var.vpc_name

  }
}
resource "aws_subnet" "mod_pub1" {
  vpc_id = aws_vpc.module_vpc.id
  cidr_block = var.block3
  map_public_ip_on_launch = true
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "mod_pub2" {
  vpc_id                  = aws_vpc.module_vpc.id
  cidr_block              = var.block4
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2b"
}

resource "aws_subnet" "mod_private" {
  vpc_id = aws_vpc.module_vpc.id
  cidr_block = var.block5
  #map_public_ip_on_launch = true
  availability_zone = "us-west-2c"
}

resource "aws_internet_gateway" "mod_igw" {

  vpc_id = aws_vpc.module_vpc.id
}

resource "aws_route_table" "mod_route" {
  vpc_id = aws_vpc.module_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mod_igw.id
  }
}

resource "aws_route_table_association" "mod_routetable_association" {

  for_each = {

    subnet1= aws_subnet.mod_pub1.id
    subnet2= aws_subnet.mod_pub2.id
    #subnet3= aws_subnet.mod_pub2.id
  }
  route_table_id = aws_route_table.mod_route.id
  subnet_id = each.value

}
# resource "aws_eip" "e01" {
#   vpc = true
# }
# resource "aws_nat_gateway" "nat01" {
#   subnet_id = aws_subnet.mod_private
#   allocation_id = aws_eip.e01.id
# }
# resource "aws_eip" "e02" {
#   vpc = true
# }
# resource "aws_route_table" "prirt" {
#   vpc_id = aws_vpc.module_vpc.id
#
#  route {
#   cidr_block = var.block4
#   nat_gateway_id = aws_nat_gateway.nat01.id
#  }
# }
# resource "aws_route_table_association" "prirta1" {
#   route_table_id = aws_route_table.prirt.id
#   subnet_id      = aws_subnet.mod_private
#
# }
resource "aws_launch_configuration" "mod_launch" {
  image_id      = var.amiid
  instance_type = var.machinetype
  key_name = var.keyname
  name_prefix = "mod-"
  security_groups = [aws_security_group.module_Sg.id]
  lifecycle {

    create_before_destroy = true
  }
}

resource "aws_elb" "mod_elb" {

  name = "mod-elb"
  security_groups = [aws_security_group.module_Sg.id]
  subnets = [aws_subnet.mod_pub1.id,aws_subnet.mod_pub2.id]
  cross_zone_load_balancing = true
  health_check {
    healthy_threshold   = 2
    interval            = 30
    target              = "HTTP:80/index.html"
    timeout             = 3
    unhealthy_threshold = 2
  }

listener {

    instance_port     = "80"
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
}
}
# resource "aws_db_instance" "web_db" {
#   identifier        = "web-db"
#   allocated_storage = 20
#   engine            = "mysql"
#   instance_class    = "db.t2.micro"
#   #name              = "webapp"
#   username          = "admin"
#   password          = "Admin12345"
#   skip_final_snapshot = true
#   vpc_security_group_ids = [aws_security_group.module_Sg.id]
#   db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
# }

#resource "aws_db_subnet_group" "db_subnet" {
  #name       = "db-subnet"
  #subnet_ids = [aws_subnet.mod_private]
#}
resource "aws_autoscaling_group" "mod_auto" {
  name = "Module-ASG1"
  max_size             = 3
  min_size             = 2
  desired_capacity     = 2
  #availability_zones   = ["us-west-2a","us-west-2b","us-west-2c"]
  vpc_zone_identifier  = [aws_subnet.mod_pub1.id, aws_subnet.mod_pub2.id]
  launch_configuration = aws_launch_configuration.mod_launch.id
  load_balancers = [aws_elb.mod_elb.id]
  metrics_granularity  = "1minute"
  lifecycle {

    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "web"

      }

}
