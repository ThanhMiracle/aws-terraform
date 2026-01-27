# LAB-1
## ✅ Results
### Install awscli on ec2
![Lab1-image-0](aws_images/use_awscli_in_ec2.jpeg)
---------------------------------------

### Policy Added
![Lab1-image-0](aws_images/s3_policy.jpeg)
----------------------------------------
### Confirm policy to view Buckets from EC2
![Lab1-image-0](aws_images/bucket_iam_policy.jpeg)

# LAB-2
## ✅ Results
### Confirm Nginx is installed
![Lab1-image-0](aws_images/nginx_installed.jpeg)
-----------------
### Access through browser
![Lab1-image-0](aws_images/nginx_installed_1.jpeg)

### EBS mount in EC2
![Lab1-image-0](aws_images/ebs_mount.jpeg)

### Create 2  private subnet , 2 public subnet , 1 natgateway , 1 internet gateway

![Lab1-image-0](aws_images/tf_output_public_private_ip.jpeg)

- Internet Gateway for public EC2
![Lab1-image-0](aws_images/igw.jpeg)

- NAT gateway for private EC2


- Setup inbound and outbound rules for each EC2
![Lab1-image-0](aws_images/inboud_outbound_rules.jpeg)

- SSH into public EC2
![Lab1-image-0](aws_images/ssh_to_public_ip.jpeg)
- SSH from public one to private one
![Lab1-image-0](aws_images/from_public_to_private.jpeg)


# LAB-3
### EBS mount in EC2
![Lab1-image-0](aws_images/ebs_mount.jpeg)

# LAB-4

### Create ALB and ASG , bucket attached to ASG
![Lab1-image-0](aws_images/ALB_ASG.jpeg)

### Access from browser through ALB's DNS
![Lab1-image-0](aws_images/access_through_lb-dns.jpeg)