# Local variables for user data and AMIs
locals {
  networker_ami = (var.aws_region == "us-east-1" || var.use_marketplace_amis) && lookup(local.networker_ami_map, var.aws_region, "") != "" ? local.networker_ami_map[var.aws_region] : data.aws_ami.amazon_linux_2.id
  ddve_ami      = (var.aws_region == "us-east-1" || var.use_marketplace_amis) && lookup(local.ddve_ami_map, var.aws_region, "") != "" ? local.ddve_ami_map[var.aws_region] : data.aws_ami.amazon_linux_2.id

  # NetWorker user data for marketplace AMI
  networker_marketplace_user_data = <<-EOF
    #!/bin/bash
    # NetWorker Virtual Edition - minimal configuration
    # The NetWorker VE AMI comes pre-configured
    
    # Log startup
    echo "NetWorker VE instance starting from marketplace AMI" > /var/log/user-data.log
    echo "Default SSH: admin@<public-ip> (password: <private-ip>)" >> /var/log/user-data.log
    echo "Default URL: https://<public-ip>:9090" >> /var/log/user-data.log
    echo "Console will be available after services start (3-5 minutes)" >> /var/log/user-data.log
    echo "Instance Type: ${var.use_spot_instances ? "SPOT" : "ON-DEMAND"}" >> /var/log/user-data.log
    
    # Do not set hostname here - NetWorker VE requires specific procedure
    # Hostname will be configured by Ansible following NetWorker VE requirements
    echo "Hostname configuration will be done by Ansible" >> /var/log/user-data.log
    
    # Note: Additional configuration should be done through NetWorker Management Console
  EOF

  # NetWorker user data for simulation mode
  networker_simulation_user_data = <<-EOF
    #!/bin/bash
    # Simulation mode - using Amazon Linux
    yum update -y
    yum install -y wget curl jq git python3 python3-pip
    
    hostnamectl set-hostname networker-lab-server-01.${var.internal_domain_name}
    echo "127.0.0.1 networker-lab-server-01.${var.internal_domain_name} networker-lab-server-01 networker" >> /etc/hosts
    
    # Create networker user
    useradd -m -s /bin/bash networker
    echo "networker ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/networker
    
    # Prepare for NetWorker installation
    mkdir -p /opt/networker/install
    chown -R networker:networker /opt/networker
    
    echo "NetWorker Server simulation mode initialization complete" > /var/log/user-data.log
    echo "Instance Type: ${var.use_spot_instances ? "SPOT" : "ON-DEMAND"}" >> /var/log/user-data.log
  EOF

  # DDVE user data for marketplace AMI
  ddve_marketplace_user_data = <<-EOF
    #!/bin/bash
    # DDVE Marketplace AMI - minimal configuration
    # The DDVE AMI comes pre-configured, just set hostname
    
    # Log startup
    echo "DDVE instance starting from marketplace AMI" > /var/log/user-data.log
    echo "Default credentials: sysadmin / <instance-id> (will be changed to Changeme123!)" >> /var/log/user-data.log
    echo "Web UI will be available at https://<public-ip>" >> /var/log/user-data.log
    echo "Instance Type: ${var.use_spot_instances ? "SPOT" : "ON-DEMAND"}" >> /var/log/user-data.log
    echo "Disk configuration:" >> /var/log/user-data.log
    echo "  - Root disk: /dev/sda (250GB)" >> /var/log/user-data.log
    echo "  - NVRAM disk: /dev/sdb (10GB)" >> /var/log/user-data.log
    echo "  - Metadata disk: /dev/sdc (200GB)" >> /var/log/user-data.log
    echo "  - S3 bucket: ${aws_s3_bucket.ddve_cloud_tier.id}" >> /var/log/user-data.log
    
    # Note: DDVE will automatically configure disks during initial setup
  EOF

  # DDVE user data for simulation mode
  ddve_simulation_user_data = <<-EOF
    #!/bin/bash
    # Simulation mode - using Amazon Linux
    yum update -y
    yum install -y wget curl jq aws-cli
    
    hostnamectl set-hostname networker-lab-ddve-01.${var.internal_domain_name}
    echo "127.0.0.1 networker-lab-ddve-01.${var.internal_domain_name} networker-lab-ddve-01 ddve" >> /etc/hosts
    
    aws configure set region ${var.aws_region}
    
    # No additional disk in cost-optimized configuration - using S3 for storage
    
    echo "DDVE simulation mode initialization complete" > /var/log/user-data.log
    echo "Instance Type: ${var.use_spot_instances ? "SPOT" : "ON-DEMAND"}" >> /var/log/user-data.log
  EOF

  # Select appropriate user data based on configuration
  networker_user_data = (var.aws_region == "us-east-1" || var.use_marketplace_amis) ? local.networker_marketplace_user_data : local.networker_simulation_user_data
  ddve_user_data      = (var.aws_region == "us-east-1" || var.use_marketplace_amis) ? local.ddve_marketplace_user_data : local.ddve_simulation_user_data
}

# NetWorker Server Instance (On-Demand)
resource "aws_instance" "networker_server" {
  count = var.use_spot_instances ? 0 : 1

  ami                    = local.networker_ami
  instance_type          = var.instance_types.networker_server
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.networker_server.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_type = "gp3"
    volume_size = var.storage_sizes.networker_server
    encrypted   = true

    tags = {
      Name = "${var.project_name}-networker-server-root"
    }
  }

  # Additional 600GB st1 disk for NetWorker data (required by avi-cli validation)
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "st1"
    volume_size = 600
    encrypted   = true

    tags = {
      Name = "${var.project_name}-networker-server-data"
    }
  }

  user_data = base64encode(local.networker_user_data)

  tags = {
    Name         = "${var.project_name}-networker-server"
    Role         = "NetWorker-Server"
    Environment  = var.environment
    InstanceType = "on-demand"
  }
}

# NetWorker Server Instance (Spot)
resource "aws_instance" "networker_server_spot" {
  count = var.use_spot_instances ? 1 : 0

  ami                    = local.networker_ami
  instance_type          = var.instance_types.networker_server
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.networker_server.id]
  subnet_id              = aws_subnet.public.id

  instance_market_options {
    market_type = "spot"

    spot_options {
      max_price                      = var.spot_price
      spot_instance_type             = "persistent"
      instance_interruption_behavior = "stop"
    }
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.storage_sizes.networker_server
    encrypted   = true

    tags = {
      Name = "${var.project_name}-networker-server-root"
    }
  }

  # Additional 600GB st1 disk for NetWorker data (required by avi-cli validation)
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "st1"
    volume_size = 600
    encrypted   = true

    tags = {
      Name = "${var.project_name}-networker-server-data"
    }
  }

  user_data = base64encode(local.networker_user_data)

  tags = {
    Name         = "${var.project_name}-networker-server"
    Role         = "NetWorker-Server"
    Environment  = var.environment
    InstanceType = "spot"
  }
}

# DDVE Instance (On-Demand)
resource "aws_instance" "ddve" {
  count = var.use_spot_instances ? 0 : 1

  ami                    = local.ddve_ami
  instance_type          = var.instance_types.ddve
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.ddve.id]
  subnet_id              = aws_subnet.public.id
  iam_instance_profile   = aws_iam_instance_profile.ddve.name


  # Force IMDSv2 for better security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.storage_sizes.ddve
    encrypted   = true

    tags = {
      Name = "${var.project_name}-ddve-root"
    }
  }

  # NVRAM disk required for DDVE operation (even with S3 storage)
  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_type           = "gp3"
    volume_size           = 10 # 10GB NVRAM disk
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name    = "${var.project_name}-ddve-nvram"
      Purpose = "DDVE NVRAM Cache"
    }
  }

  # Metadata disk for DDVE deduplication metadata
  ebs_block_device {
    device_name           = "/dev/sdc"
    volume_type           = "gp3"
    volume_size           = 200 # 200GB metadata disk (minimum for DDVE)
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name    = "${var.project_name}-ddve-metadata"
      Purpose = "DDVE Deduplication Metadata"
    }
  }

  user_data = base64encode(local.ddve_user_data)

  tags = {
    Name         = "${var.project_name}-ddve"
    Role         = "DDVE"
    Environment  = var.environment
    InstanceType = "on-demand"
  }
}

# DDVE Instance (Spot)
resource "aws_instance" "ddve_spot" {
  count = var.use_spot_instances ? 1 : 0

  ami                    = local.ddve_ami
  instance_type          = var.instance_types.ddve
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.ddve.id]
  subnet_id              = aws_subnet.public.id
  iam_instance_profile   = aws_iam_instance_profile.ddve.name

  instance_market_options {
    market_type = "spot"

    spot_options {
      max_price                      = var.spot_price
      spot_instance_type             = "persistent"
      instance_interruption_behavior = "stop"
    }
  }


  # Force IMDSv2 for better security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.storage_sizes.ddve
    encrypted   = true

    tags = {
      Name = "${var.project_name}-ddve-root"
    }
  }

  # NVRAM disk required for DDVE operation (even with S3 storage)
  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_type           = "gp3"
    volume_size           = 10 # 10GB NVRAM disk
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name    = "${var.project_name}-ddve-nvram"
      Purpose = "DDVE NVRAM Cache"
    }
  }

  # Metadata disk for DDVE deduplication metadata
  ebs_block_device {
    device_name           = "/dev/sdc"
    volume_type           = "gp3"
    volume_size           = 200 # 200GB metadata disk (minimum for DDVE)
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name    = "${var.project_name}-ddve-metadata"
      Purpose = "DDVE Deduplication Metadata"
    }
  }

  user_data = base64encode(local.ddve_user_data)

  tags = {
    Name         = "${var.project_name}-ddve"
    Role         = "DDVE"
    Environment  = var.environment
    InstanceType = "spot"
  }
}

# Linux Client Instance (On-Demand)
resource "aws_instance" "linux_client" {
  count = var.use_spot_instances ? 0 : 1

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_types.linux_client
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.linux_client.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_type = "gp3"
    volume_size = var.storage_sizes.linux_client
    encrypted   = true

    tags = {
      Name = "${var.project_name}-linux-client-root"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Set hostname
    hostnamectl set-hostname networker-lab-linux-01.${var.internal_domain_name}
    echo "127.0.0.1 networker-lab-linux-01.${var.internal_domain_name} networker-lab-linux-01 linux-client" >> /etc/hosts
    
    # Update system
    dnf update -y
    
    # Install required packages
    dnf install -y wget curl python3 python3-pip
    
    # Create test data
    mkdir -p /data/test
    dd if=/dev/urandom of=/data/test/sample1.dat bs=1M count=100
    dd if=/dev/urandom of=/data/test/sample2.dat bs=1M count=100
    
    # Log completion
    echo "Linux client initialization complete" > /var/log/user-data.log
    echo "Instance Type: ON-DEMAND" >> /var/log/user-data.log
  EOF
  )

  tags = {
    Name         = "${var.project_name}-linux-client"
    Role         = "Linux-Client"
    Environment  = var.environment
    InstanceType = "on-demand"
  }
}

# Linux Client Instance (Spot)
resource "aws_instance" "linux_client_spot" {
  count = var.use_spot_instances ? 1 : 0

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_types.linux_client
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.linux_client.id]
  subnet_id              = aws_subnet.public.id

  instance_market_options {
    market_type = "spot"

    spot_options {
      max_price                      = var.spot_price
      spot_instance_type             = "persistent"
      instance_interruption_behavior = "stop"
    }
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.storage_sizes.linux_client
    encrypted   = true

    tags = {
      Name = "${var.project_name}-linux-client-root"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Set hostname
    hostnamectl set-hostname networker-lab-linux-01.${var.internal_domain_name}
    echo "127.0.0.1 networker-lab-linux-01.${var.internal_domain_name} networker-lab-linux-01 linux-client" >> /etc/hosts
    
    # Update system
    dnf update -y
    
    # Install required packages
    dnf install -y wget curl python3 python3-pip
    
    # Create test data
    mkdir -p /data/test
    dd if=/dev/urandom of=/data/test/sample1.dat bs=1M count=100
    dd if=/dev/urandom of=/data/test/sample2.dat bs=1M count=100
    
    # Log completion
    echo "Linux client initialization complete" > /var/log/user-data.log
    echo "Instance Type: SPOT" >> /var/log/user-data.log
  EOF
  )

  tags = {
    Name         = "${var.project_name}-linux-client"
    Role         = "Linux-Client"
    Environment  = var.environment
    InstanceType = "spot"
  }
}

# Windows Client Instance (On-Demand)
resource "aws_instance" "windows_client" {
  count = var.use_spot_instances ? 0 : 1

  ami                    = data.aws_ami.windows_2022.id
  instance_type          = var.instance_types.windows_client
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.windows_client.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_type = "gp3"
    volume_size = var.storage_sizes.windows_client
    encrypted   = true

    tags = {
      Name = "${var.project_name}-windows-client-root"
    }
  }

  user_data = base64encode(<<-EOF
    <powershell>
    # Set hostname
    Rename-Computer -NewName "networker-lab-windows-01" -Force
    
    # Enable WinRM for Ansible - robust configuration
    try {
        # Method 1: Try downloading Ansible's official script
        $url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
        $file = "$env:temp\ConfigureRemotingForAnsible.ps1"
        $webClient = New-Object -TypeName System.Net.WebClient
        $webClient.DownloadFile($url, $file)
        powershell.exe -ExecutionPolicy ByPass -File $file
        Write-Output "WinRM configured using Ansible script"
    }
    catch {
        # Method 2: Fallback to manual WinRM configuration
        Write-Output "Fallback: Configuring WinRM manually"
        
        # Enable WinRM service
        Enable-PSRemoting -Force -SkipNetworkProfileCheck
        
        # Configure WinRM for both HTTP and HTTPS
        winrm quickconfig -q
        winrm set winrm/config/service '@{AllowUnencrypted="true"}'
        winrm set winrm/config/service/auth '@{Basic="true"}'
        winrm set winrm/config/client/auth '@{Basic="true"}'
        winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port="5985"}'
        
        # Create self-signed certificate for HTTPS
        $cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
        winrm create winrm/config/listener?Address=*+Transport=HTTPS "@{Hostname=`"$env:COMPUTERNAME`";CertificateThumbprint=`"$($cert.Thumbprint)`"}"
        
        # Configure firewall
        netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985
        netsh advfirewall firewall add rule name="WinRM HTTPS" dir=in action=allow protocol=TCP localport=5986
        
        Write-Output "Manual WinRM configuration completed"
    }
    
    # Create test data
    New-Item -ItemType Directory -Path "C:\TestData" -Force
    $random = New-Object System.Random
    $bytes = New-Object byte[] 104857600  # 100MB
    $random.NextBytes($bytes)
    [System.IO.File]::WriteAllBytes("C:\TestData\sample1.dat", $bytes)
    $random.NextBytes($bytes)
    [System.IO.File]::WriteAllBytes("C:\TestData\sample2.dat", $bytes)
    
    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    
    # Log completion
    "Windows client initialization complete" | Out-File C:\user-data.log
    "Instance Type: ON-DEMAND" | Out-File -Append C:\user-data.log
    
    # Restart
    Restart-Computer -Force
    </powershell>
  EOF
  )

  tags = {
    Name         = "${var.project_name}-windows-client"
    Role         = "Windows-Client"
    Environment  = var.environment
    InstanceType = "on-demand"
  }
}

# Windows Client Instance (Spot)
resource "aws_instance" "windows_client_spot" {
  count = var.use_spot_instances ? 1 : 0

  ami                    = data.aws_ami.windows_2022.id
  instance_type          = var.instance_types.windows_client
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.windows_client.id]
  subnet_id              = aws_subnet.public.id

  instance_market_options {
    market_type = "spot"

    spot_options {
      max_price                      = var.spot_price
      spot_instance_type             = "persistent"
      instance_interruption_behavior = "stop"
    }
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.storage_sizes.windows_client
    encrypted   = true

    tags = {
      Name = "${var.project_name}-windows-client-root"
    }
  }

  user_data = base64encode(<<-EOF
    <powershell>
    # Set hostname
    Rename-Computer -NewName "networker-lab-windows-01" -Force
    
    # Enable WinRM for Ansible - robust configuration
    try {
        # Method 1: Try downloading Ansible's official script
        $url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
        $file = "$env:temp\ConfigureRemotingForAnsible.ps1"
        $webClient = New-Object -TypeName System.Net.WebClient
        $webClient.DownloadFile($url, $file)
        powershell.exe -ExecutionPolicy ByPass -File $file
        Write-Output "WinRM configured using Ansible script"
    }
    catch {
        # Method 2: Fallback to manual WinRM configuration
        Write-Output "Fallback: Configuring WinRM manually"
        
        # Enable WinRM service
        Enable-PSRemoting -Force -SkipNetworkProfileCheck
        
        # Configure WinRM for both HTTP and HTTPS
        winrm quickconfig -q
        winrm set winrm/config/service '@{AllowUnencrypted="true"}'
        winrm set winrm/config/service/auth '@{Basic="true"}'
        winrm set winrm/config/client/auth '@{Basic="true"}'
        winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port="5985"}'
        
        # Create self-signed certificate for HTTPS
        $cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
        winrm create winrm/config/listener?Address=*+Transport=HTTPS "@{Hostname=`"$env:COMPUTERNAME`";CertificateThumbprint=`"$($cert.Thumbprint)`"}"
        
        # Configure firewall
        netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985
        netsh advfirewall firewall add rule name="WinRM HTTPS" dir=in action=allow protocol=TCP localport=5986
        
        Write-Output "Manual WinRM configuration completed"
    }
    
    # Create test data
    New-Item -ItemType Directory -Path "C:\TestData" -Force
    $random = New-Object System.Random
    $bytes = New-Object byte[] 104857600  # 100MB
    $random.NextBytes($bytes)
    [System.IO.File]::WriteAllBytes("C:\TestData\sample1.dat", $bytes)
    $random.NextBytes($bytes)
    [System.IO.File]::WriteAllBytes("C:\TestData\sample2.dat", $bytes)
    
    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    
    # Log completion
    "Windows client initialization complete" | Out-File C:\user-data.log
    "Instance Type: SPOT" | Out-File -Append C:\user-data.log
    
    # Restart
    Restart-Computer -Force
    </powershell>
  EOF
  )

  tags = {
    Name         = "${var.project_name}-windows-client"
    Role         = "Windows-Client"
    Environment  = var.environment
    InstanceType = "spot"
  }
}

# Elastic IP for Linux Client
resource "aws_eip" "linux_client" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-linux-client-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# Associate EIP with Linux Client (On-Demand)
resource "aws_eip_association" "linux_client" {
  count         = var.use_spot_instances ? 0 : 1
  instance_id   = aws_instance.linux_client[0].id
  allocation_id = aws_eip.linux_client.id
}

# Associate EIP with Linux Client (Spot)
resource "aws_eip_association" "linux_client_spot" {
  count         = var.use_spot_instances ? 1 : 0
  instance_id   = aws_instance.linux_client_spot[0].id
  allocation_id = aws_eip.linux_client.id
}

# Elastic IP for Windows Client
resource "aws_eip" "windows_client" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-windows-client-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# Associate EIP with Windows Client (On-Demand)
resource "aws_eip_association" "windows_client" {
  count         = var.use_spot_instances ? 0 : 1
  instance_id   = aws_instance.windows_client[0].id
  allocation_id = aws_eip.windows_client.id
}

# Associate EIP with Windows Client (Spot)
resource "aws_eip_association" "windows_client_spot" {
  count         = var.use_spot_instances ? 1 : 0
  instance_id   = aws_instance.windows_client_spot[0].id
  allocation_id = aws_eip.windows_client.id
}