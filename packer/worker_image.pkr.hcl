packer {
  required_plugins {
    amazon = {
      version = ">= 1.8.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "jenkins_worker" {
  ami_name      = "jenkins-basic-worker-1.2"
  instance_type = "t2.medium"
  region        = "us-east-1"

  vpc_id                   = "vpc-0d28ed02b7f57d168"
  subnet_id                = "subnet-04f372e67472f5701"
  associate_public_ip_address = true

  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  ssh_username = "ec2-user"

  run_tags = {
    Owner = "David"
  }

  tags = {
    Owner = "David"
  }
}

build {
  sources = ["source.amazon-ebs.jenkins_worker"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y git wget curl unzip jq tree htop ncdu",
      "sudo yum install yum-utils shadow-utils git docker java-17-amazon-corretto -y",
      "sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo",
      "sudo yum -y install terraform",
      "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "sudo yum install -y python3 python3-pip",
      "pip3 install --upgrade pip",
      "sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.47.0/trivy_0.47.0_Linux-64bit.rpm",
      "sudo usermod -a -G docker ec2-user",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo yum clean all",
      "sudo rm -rf /var/cache/yum"
    ]
  }
}
