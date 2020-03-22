provider "aws" {
  region = "us-west-2"
}
resource "aws_instance" "centos" {
  ami           = "ami-a042f4d8"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.my-key.key_name}"
  subnet_id     = "subnet-23c1df6a"  #xlabs-all-customers-dev-private-2a
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}","${aws_security_group.allow_http_80.id}","${aws_security_group.allow_all_outbound.id}"]
tags {
    Name = "wordpress-server"
    }
}
resource "null_resource" "wp_provisioning" {
    depends_on = ["aws_instance.centos"]
    provisioner "local-exec" {
        command = "echo [wordpress] > ansible/hosts;echo ${aws_instance.centos.private_ip} >> ansible/hosts"
        }
    provisioner "local-exec" {
        command = "ansible-playbook -u centos --private-key ~/.ssh/id_rsa ansible/provision_wp.yml -i ansible/hosts"
        }
}
resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  vpc_id = "vpc-b905dedf"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "allow_http_80" {
  name = "allow_http_80"
  vpc_id = "vpc-b905dedf"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "allow_all_outbound" {
  name = "allow_all_outbound"
  vpc_id = "vpc-b905dedf"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "my-key" {
    key_name = "my-key"
    public_key = "${file("~/.ssh/id_rsa.pub")}"
}
output "private_ip" {
  value = "${aws_instance.centos.private_ip}"
}


