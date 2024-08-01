# Ubuntu Server Focal
# ---
# Packer Template to create an Ubuntu Server (Focal) on Proxmox

# Variable Definitions
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

# Resource Definiation for the VM Template
source "proxmox-iso" "ubuntu-server-focal" {
 
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # (Optional) Skip TLS Verification
    # insecure_skip_tls_verify = true
    
    # VM General Settings
    node = "proxmox"
    # vm_id = "200"
    vm_name = "ubuntu-server-focal"
    template_description = "Ubuntu Server Focal Image"

    # VM OS Settings
    # (Option 1) Local ISO File
    iso_file = "local:iso/ubuntu-20.04.6-live-server-amd64.iso"
    # - or -
    # (Option 2) Download ISO
    # iso_url = "https://releases.ubuntu.com/20.04/ubuntu-20.04.3-live-server-amd64.iso"
    # iso_checksum = "f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
    iso_storage_pool = "local"
    unmount_iso = true

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size = "20G"
        storage_pool = "local-lvm"
        type = "virtio"
    }

    # VM CPU Settings
    cores = "1"
    
    # VM Memory Settings
    memory = "8192" 

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    } 

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

    # PACKER Boot Commands
    boot_command = [
        "<esc><wait><esc><wait>",
        "<f6><wait><esc><wait>",
        "<bs><bs><bs><bs><bs>",
        "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
        "--- <enter>"
    ]
    boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "http" 
    # (Optional) Bind IP Address and Port
    http_bind_address = "192.168.8.50"
    # http_port_min = 8802
    # http_port_max = 8802

    ssh_username = "ubuntu"

    # (Option 1) Add your Password here
    # ssh_password = "ubuntu"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    ssh_private_key_file = "~/.ssh/id_ed25519"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

    name = "ubuntu-server-focal"
    sources = ["source.proxmox-iso.ubuntu-server-focal"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }

    provisioner "shell" {
        inline = [
            "sudo apt-get install -y postgresql-12",
            "sudo -u postgres createuser $USER",
            "sudo -u postgres psql -c \"alter user $USER with superuser\" postgres",
            "sudo -u postgres createuser canvas --no-createdb --no-superuser --no-createrole",
            "psql -d postgres -c \"ALTER USER canvas WITH PASSWORD 'your_password';\"",
            "sudo -u postgres createdb canvas_production --owner=canvas",
            "sudo apt-get install -y git-core",
            "git clone https://github.com/instructure/canvas-lms.git canvas",
            "cd canvas",
            "git checkout prod",
            "sudo mv ../canvas /var/",
            "sudo apt-get install -y software-properties-common",
            "sudo add-apt-repository -y ppa:instructure/ruby",
            "sudo apt-get update",
            "sudo apt-get install -y ruby3.1 ruby3.1-dev zlib1g-dev libxml2-dev libsqlite3-dev postgresql libpq-dev libxmlsec1-dev libyaml-dev libidn11-dev curl make g++",
            "curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -",
            "sudo apt-get install -y nodejs",
            "sudo npm install -g npm@latest",
            "sudo gem uninstall stringio; sudo gem install stringio -v 3.1.1;",
            "sudo gem uninstall base64; sudo gem install base64 -v 0.2.0",
            "sudo gem install bundler --version 2.5.10",
            "bundle config set --local path vendor/bundle",
            "bundle install",
            "curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -",
            "echo 'deb https://dl.yarnpkg.com/debian/ stable main' | sudo tee /etc/apt/sources.list.d/yarn.list",
            "sudo apt-get update && sudo apt-get install yarn=1.19.1-1",
            "yarn install",
            "for config in amazon_s3 database vault_contents delayed_jobs domain file_store outgoing_mail security external_migration; do cp config/$config.yml.example config/$config.yml; done"
        ]
    }

    provisioner "file" {
        source = "./canvasconfig/database.yml"
        destination = "/var/canvas/config/database.yml"
    }

    provisioner "file" {
        source = "./canvasconfig/dynamic_settings.yml"
        destination = "/var/canvas/config/dynamic_settings.yml"
    }

    provisioner "file" {
        source = "./canvasconfig/outgoing_mail.yml"
        destination = "/var/canvas/config/outgoing_mail.yml"
    }

    provisioner "file" {
        source = "./canvasconfig/domain.yml"
        destination = "/var/canvas/config/domain.yml"
    }

    provisioner "file" {
        source = "./canvasconfig/security.yml"
        destination = "/var/canvas/config/security.yml"
    }

    provisioner "shell" {
        inline = [
            "cd /var/canvas/",
            "export CANVAS_LMS_ADMIN_EMAIL=soycabanillas@gmail.com",
            "export CANVAS_LMS_ADMIN_PASSWORD=thisiasfkddleeww##@@qq12kfkjsdfjfkfkkffkkfj",
            "export CANVAS_LMS_ACCOUNT_NAME=Cabanillas",
            "export CANVAS_LMS_STATS_COLLECTION=opt_out",
            "yarn gulp rev",
            "RAILS_ENV=production bundle exec rake db:initial_setup",
            "mkdir -p log tmp/pids public/assets app/stylesheets/brandable_css_brands",
            "touch app/stylesheets/_brandable_variables_defaults_autogenerated.scss",
            "touch Gemfile.lock",
            "touch log/production.log",
            "sudo adduser --disabled-password --gecos canvas canvasuser",
            "sudo chown -R canvasuser config/environment.rb log tmp public/assets app/stylesheets/_brandable_variables_defaults_autogenerated.scss app/stylesheets/brandable_css_brands Gemfile.lock config.ru",
            "RAILS_ENV=production bundle exec rake canvas:compile_assets",


            "sudo apt-get install -y apache2",
            "sudo apt-get install -y dirmngr gnupg apt-transport-https ca-certificates",
            "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7",
            "sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger $(lsb_release -cs) main > /etc/apt/sources.list.d/passenger.list'",
            "sudo apt-get update",
            "sudo apt-get install -y libapache2-mod-passenger",
            "sudo a2enmod rewrite",
            "sudo a2enmod ssl",
            "sudo unlink /etc/apache2/sites-enabled/000-default.conf",
            
            
            "sudo chown -R canvasuser public/dist/brandable_css",
            "sudo chown canvasuser config/*.yml",
            "sudo chmod 400 config/*.yml"
        ]
    }

    provisioner "file" {
        source = "./canvasconfig/canvas.conf"
        destination = "/tmp/canvas.conf"
    }


    provisioner "shell" {
        inline = [
            "sudo mv /tmp/canvas.conf /etc/apache2/sites-available/canvas.conf",
            "cd /var/canvas/",
            "sudo a2ensite canvas",
            "sudo systemctl reload apache2"
        ]
    }

    provisioner "file" {
        source = "./postgresconfig.sh"
        destination = "/tmp/postgresconfig.sh"
    }

    provisioner "shell" {
        inline = [
            "chmod +x /tmp/postgresconfig.sh",
            "sudo /tmp/postgresconfig.sh",
            "rm /tmp/postgresconfig.sh"
        ]
    }
}
