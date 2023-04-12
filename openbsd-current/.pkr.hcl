locals {
  version      = "0.1.1"
  ssh_password = "toor"
}

source "virtualbox-iso" "default" {
  guest_os_type = "OpenBSD_64"

  # Use 2 vCPUs to install OpenBSD, so that it will use the bsd.mp kernel.
  cpus = 2

  # The VM needs 1024 MB of RAM in order install successfully.
  memory = 1228

  disk_size            = 256000 # 256 GB
  hard_drive_interface = "scsi"
  nic_type             = "virtio"

  iso_url      = "https://cdn.openbsd.org/pub/OpenBSD/snapshots/amd64/install73.iso"
  iso_checksum = "file:https://cdn.openbsd.org/pub/OpenBSD/snapshots/amd64/SHA256"

  ssh_username = "root"
  ssh_password = local.ssh_password
  ssh_timeout = "30m"

  guest_additions_mode = "disable" # OpenBSD is unsupported
  acpi_shutdown        = true

  http_content = {
    "/install.conf" = templatefile("install.conf.template", {
      root_password = local.ssh_password
      disklabel_url = "https://raw.githubusercontent.com/moritzbuhl/emulate-OpenBSD/main/openbsd-snapshots/disklabel.template"
    })
  }

  boot_wait = "20s"
  boot_command = [
    "A<enter>",
    "<wait>",
    "http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.conf<enter>",
  ]
}

build {
  sources = ["sources.virtualbox-iso.default"]

  provisioner "file" {
    source      = "${path.root}/sshd_config"
    destination = "/etc/ssh/sshd_config"
  }

  provisioner "file" {
    source      = "${path.root}/boot.conf"
    destination = "/etc/boot.conf"
  }

  provisioner "file" {
    source      = "${path.root}/doas.conf"
    destination = "/etc/doas.conf"
  }

  provisioner "file" {
    source      = "${path.root}/authorized_keys"
    destination = ".ssh/authorized_keys"
  }

  provisioner "file" {
    source      = "${path.root}/authorized_keys"
    destination = ".ssh/authorized_keys"
  }

  # Disable unnecessary services to save CPU cycles.
  provisioner "shell" {
    inline = [
      "rcctl disable check_quotas cron library_aslr ntpd pf pflogd slaacd smtpd sndiod",
    ]
  }

  provisioner "shell" {
    inline = ["pkg_add git got cmake meson autoconf-2.71 automake-1.16.5 libtool llvm rust"]
  }

  # Disable KARL (since it's useless in a CI/CD VM) and set date and time at first-boot
  # in one fell swoop.
  provisioner "shell" {
    inline = ["sed -i 's|/usr/libexec/reorder_kernel &|rdate time.cloudflare.com|' /etc/rc"]
  }

  # syspatch(8) may sometimes "fail" (with an exit code of 2) if it must update
  # itself first. No worries -- just gotta run it again.
  provisioner "shell" {
    inline           = ["syspatch || true"]
    valid_exit_codes = [0, 2]
  }
  provisioner "shell" {
    inline = ["syspatch || true"]
  }

  post-processors {
    post-processor "vagrant" {
      vagrantfile_template_generated = false
    }
  }
}
