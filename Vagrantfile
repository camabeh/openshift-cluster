enable_proxy = true
http_proxy = "..."
https_proxy = "..."
no_proxy = "localhost,127.0.0.1,10.1.0.0/16,172.30.0.0/16,.nip.io,docker-registry.default.svc.cluster.local,docker-registry.default.svc"

nodes = {
    #             Count, 192.168.100.X, CPU count, Memory, Ext storage size
    'master' => [1, 10, 2, 8192],
    'node' => [2, 20, 2, 4096, 10 * 1024]
}

Vagrant.configure("2") do |config|

  if enable_proxy
    unless Vagrant.has_plugin?("vagrant-proxyconf")
      raise 'vagrant-proxyconf is not installed. Install with: vagrant plugin install vagrant-proxyconf'
    end
    config.proxy.http = http_proxy
    config.proxy.https = https_proxy
    config.proxy.no_proxy = no_proxy
  end

  # Defaults (VirtualBox)
  config.vm.box = "centos/7"
  config.vm.synced_folder '.', '/vagrant', disabled: true

  nodes.each do |node_type, (count, ip_end, cpu_count, memory, ext_storage_size)|
    count.times do |idx|
      if count > 1
        node = "#{node_type}#{idx + 1}"
      else
        node = "#{node_type}"
      end

      # Config applied for all node types
      node_idx = "#{node}-local-fix"
      config.ssh.username = "vagrant"
      config.vm.provision "file", source: "./keys/public", destination: "/tmp/authorized_keys"
      config.vm.provision "file", source: "./keys/private", destination: "/tmp/private"

      config.vm.provision :shell, :privileged => true, inline: <<-EOF
        mkdir -p /root/.ssh && \
        mv /tmp/authorized_keys /root/.ssh/authorized_keys && \
        chmod 0600 /root/.ssh/authorized_keys && \
        chown root:root /root/.ssh/authorized_keys && \
        mv /tmp/private /root/.ssh/id_rsa && \
        chmod 0600 /root/.ssh/id_rsa && \
        chown root:root /root/.ssh/id_rsa
      EOF

      config.vm.define "#{node_idx}" do |box|
        box.vm.hostname = "#{node_idx}.192.168.100.#{ip_end + idx}.nip.io"
        box.vm.network :private_network, ip: "192.168.100.#{ip_end + idx}", :netmask => "255.255.255.0"

        box.vm.provider :virtualbox do |vbox|
          vbox.name = "#{node_idx}"
          vbox.gui = false
          # Defaults
          vbox.linked_clone = true if Vagrant::VERSION =~ /^1.8/
          vbox.customize ["modifyvm", :id, "--memory", memory]
          vbox.customize ["modifyvm", :id, "--cpus", cpu_count]
          vbox.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]

          if node_type == "nfs" or node_type == "infra"
            ext_storage = "./tmp/#{node_idx}.vdi"
            unless File.exist?(ext_storage)
              vbox.customize ['createhd', '--filename', ext_storage, '--size', ext_storage_size]
            end
            vbox.customize ['storageattach', :id, '--storagectl', 'IDE', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', ext_storage]
          end
        end
      end
    end
  end
end