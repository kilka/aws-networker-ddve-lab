# Test Clients Module - Linux and Windows instances for testing backups

# Data sources for AMIs
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Linux Client Instance
resource "aws_instance" "linux_client" {
  count = var.deploy_linux_client ? 1 : 0

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.linux_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.linux_security_group_id]
  subnet_id              = var.subnet_id

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true

    tags = {
      Name = "${var.environment}-linux-client-root"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Set hostname
    hostnamectl set-hostname linux-client.dataprotection.lab
    echo "127.0.0.1 linux-client.dataprotection.lab linux-client" >> /etc/hosts
    
    # Update system
    dnf update -y
    
    # Install required packages
    dnf install -y wget curl python3 python3-pip git
    
    # Create test data directories
    mkdir -p /data/test
    mkdir -p /data/backup
    
    # Generate test data files
    echo "Creating test data files..."
    dd if=/dev/urandom of=/data/test/sample1.dat bs=1M count=100 2>/dev/null
    dd if=/dev/urandom of=/data/test/sample2.dat bs=1M count=100 2>/dev/null
    dd if=/dev/urandom of=/data/test/sample3.dat bs=1M count=50 2>/dev/null
    
    # Create some text files for testing
    for i in {1..10}; do
      echo "Test file $i content - $(date)" > /data/test/file$i.txt
    done
    
    # Log completion
    echo "Linux client initialization complete at $(date)" > /var/log/user-data.log
    echo "Hostname: linux-client.dataprotection.lab" >> /var/log/user-data.log
    echo "Test data created in /data/test" >> /var/log/user-data.log
  EOF
  )

  tags = {
    Name = "${var.environment}-linux-client"
    Type = "TestClient"
    OS   = "Linux"
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
}

# Windows Client Instance
resource "aws_instance" "windows_client" {
  count = var.deploy_windows_client ? 1 : 0

  ami                    = data.aws_ami.windows_2022.id
  instance_type          = var.windows_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.windows_security_group_id]
  subnet_id              = var.subnet_id

  root_block_device {
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true

    tags = {
      Name = "${var.environment}-windows-client-root"
    }
  }

  user_data = base64encode(<<-EOF
    <powershell>
    # Set hostname
    Rename-Computer -NewName "windows-client" -Force
    
    # Enable WinRM for remote management
    try {
        # Download and execute Ansible's WinRM configuration script
        $url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
        $file = "$env:temp\ConfigureRemotingForAnsible.ps1"
        $webClient = New-Object -TypeName System.Net.WebClient
        $webClient.DownloadFile($url, $file)
        powershell.exe -ExecutionPolicy ByPass -File $file
        Write-Output "WinRM configured using Ansible script"
    }
    catch {
        # Fallback: Manual WinRM configuration
        Write-Output "Configuring WinRM manually"
        
        # Enable WinRM service
        Enable-PSRemoting -Force -SkipNetworkProfileCheck
        
        # Configure WinRM
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
    
    # Create test data directories
    New-Item -ItemType Directory -Path "C:\TestData" -Force
    New-Item -ItemType Directory -Path "C:\BackupData" -Force
    
    # Generate test data files
    Write-Output "Creating test data files..."
    $random = New-Object System.Random
    $bytes = New-Object byte[] 104857600  # 100MB
    $random.NextBytes($bytes)
    [System.IO.File]::WriteAllBytes("C:\TestData\sample1.dat", $bytes)
    $random.NextBytes($bytes)
    [System.IO.File]::WriteAllBytes("C:\TestData\sample2.dat", $bytes)
    
    # Create 50MB file
    $bytes50 = New-Object byte[] 52428800  # 50MB
    $random.NextBytes($bytes50)
    [System.IO.File]::WriteAllBytes("C:\TestData\sample3.dat", $bytes50)
    
    # Create text files for testing
    1..10 | ForEach-Object {
        "Test file $_ content - $(Get-Date)" | Out-File "C:\TestData\file$_.txt"
    }
    
    # Install Chocolatey for package management
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    
    # Install management tools for jump box functionality
    choco install -y putty googlechrome firefox awscli
    
    # Create desktop shortcuts for internal systems
    $desktop = [Environment]::GetFolderPath("Desktop")
    
    # Create URLs for internal systems - all use HTTPS on default port 443
    # Using IPs directly since we're not using custom DNS
    @"
[InternetShortcut]
URL=https://${var.ddve_private_ip != "" ? var.ddve_private_ip : "10.0.1.100"}
"@ | Out-File "$desktop\DDVE Console.url"
    
    @"
[InternetShortcut]
URL=https://${var.avamar_private_ip != "" ? var.avamar_private_ip : "10.0.1.101"}
"@ | Out-File "$desktop\Avamar Console.url"
    
    @"
[InternetShortcut]
URL=https://${var.ppdm_private_ip != "" ? var.ppdm_private_ip : "10.0.1.102"}
"@ | Out-File "$desktop\PowerProtect Console.url"
    
    # Create info file with connection details
    @"
Data Protection Lab Jump Box Setup Complete!
============================================

Internal systems accessible at:
- DDVE:    ${var.ddve_private_ip != "" ? "https://${var.ddve_private_ip}" : "Not deployed"}
- Avamar:  ${var.avamar_private_ip != "" ? "https://${var.avamar_private_ip}" : "Not deployed"}
- PPDM:    ${var.ppdm_private_ip != "" ? "https://${var.ppdm_private_ip}" : "Not deployed"}  
- Linux:   ${var.deploy_linux_client ? "ssh ${aws_instance.linux_client[0].private_ip}" : "Not deployed"}

Tools Installed:
- PuTTY for SSH access
- Chrome & Firefox browsers for web consoles
- AWS CLI for management

Use the desktop shortcuts to access the web consoles.
All services use HTTPS on port 443.
"@ | Out-File "$desktop\Lab-Connection-Info.txt"
    
    # Log completion
    "Windows client initialization complete at $(Get-Date)" | Out-File C:\user-data.log
    "Hostname: windows-client" | Out-File -Append C:\user-data.log
    "Test data created in C:\TestData" | Out-File -Append C:\user-data.log
    
    # Schedule restart
    Restart-Computer -Force -Delay 30
    </powershell>
  EOF
  )

  tags = {
    Name = "${var.environment}-windows-client"
    Type = "TestClient"
    OS   = "Windows"
  }
}

# No EIP for Linux client - access via Windows jump box

resource "aws_eip" "windows_client" {
  count  = var.deploy_windows_client ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.environment}-windows-client-eip"
  }
}

resource "aws_eip_association" "windows_client" {
  count         = var.deploy_windows_client ? 1 : 0
  instance_id   = aws_instance.windows_client[0].id
  allocation_id = aws_eip.windows_client[0].id
}

# Route53 removed - using AWS default DNS