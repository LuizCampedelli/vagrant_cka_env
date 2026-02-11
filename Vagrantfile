# -*- mode: ruby -*-
# vi: set ft=ruby :
# =============================================================================
# CKA Practice Environment – Vagrantfile
# =============================================================================
# Two Ubuntu 22.04 VMs for Kubernetes v1.31 CKA exam practice.
#
# Quick start:
#   cp .env.example .env   # set ROOT_PASSWORD
#   vagrant up             # boots and provisions both VMs
#   vagrant ssh machine1   # SSH into control-plane node
#   vagrant ssh machine2   # SSH into worker node
# =============================================================================

# Read ROOT_PASSWORD from .env file
env_file = File.join(File.dirname(__FILE__), ".env")
root_password = "changeme"
if File.exist?(env_file)
  File.readlines(env_file).each do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    key, value = line.split("=", 2)
    root_password = value if key == "ROOT_PASSWORD" && value && !value.empty?
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  # Shared VirtualBox provider settings
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
    vb.gui = false
    vb.customize ["modifyvm", :id, "--groups", "/vagrant_cka_env"]
  end

  # ---------------------------------------------------------------------------
  # Machine 1 – Control-plane node
  # ---------------------------------------------------------------------------
  config.vm.define "machine1" do |m1|
    m1.vm.hostname = "ubuntu1"
    m1.vm.network "private_network", ip: "192.168.56.10"

    m1.vm.provision "shell",
      path: "scripts/provision.sh",
      env: { "ROOT_PASSWORD" => root_password }
  end

  # ---------------------------------------------------------------------------
  # Machine 2 – Worker node
  # ---------------------------------------------------------------------------
  config.vm.define "machine2" do |m2|
    m2.vm.hostname = "ubuntu2"
    m2.vm.network "private_network", ip: "192.168.56.11"

    m2.vm.provision "shell",
      path: "scripts/provision.sh",
      env: { "ROOT_PASSWORD" => root_password }
  end
end
