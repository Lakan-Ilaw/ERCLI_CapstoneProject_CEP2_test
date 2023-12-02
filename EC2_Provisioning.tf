provider "aws" {
  region = "us-east-1"
}
resource "aws_instance" "ERCLI_CP2_Ubuntu" {
  count         = 2
  ami           = "ami-06aa3f7caf3a30282"
  instance_type = "t2.medium"
  key_name      = "CEP2_test"
  subnet_id     = data.aws_subnet.ercli_subnet.id
  vpc_security_group_ids = [aws_security_group.ERCLI_CP2_Security_Group.id]
  tags = {
    Name = "ERCLI_CP2_Ubuntu${count.index + 1}"
  }
}

data "aws_vpcs" "ercli_vpc" {
}

data "aws_subnet" "ercli_subnet" {
  vpc_id = data.aws_vpcs.ercli_vpc.ids[0]
  availability_zone = "us-east-1a"
}

resource "aws_security_group" "ERCLI_CP2_Security_Group" {
  name_prefix = "ERCLI_CP2_SecGroup"
  vpc_id = data.aws_vpcs.ercli_vpc.ids[0]
  
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "null_resource" "EC2_Connectivity_Check" {
  count = length(aws_instance.ERCLI_CP2_Ubuntu)

  provisioner "local-exec" {
    command = <<-EOT
      max_retries=5
      retries=0
      while [ $retries -lt $max_retries ]; do
        ssh -i /home/elmerlakanilawy/CP2_test/CEP2_test.pem -o ConnectTimeout=20 -o StrictHostKeyChecking=no ubuntu@${aws_instance.ERCLI_CP2_Ubuntu[count.index].public_ip} exit && break
        retries=$((retries+1))
        sleep 10
      done

      if [ $retries -eq $max_retries ]; then
        echo "Failed to connect to the host via ssh after $max_retries attempts"
        exit 1
      fi
    EOT
  }
}
