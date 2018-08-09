#!/usr/bin/env bash

set -e

pwd=$(dirname "$(readlink -f "$0")")
openshift_version=3.10-fix

(cd "${pwd}/openshift-ansible" && git checkout release-${openshift_version})

chmod 0600 "${pwd}"/keys/*

#export VAGRANT_CWD="${pwd}" # bug in vagrant, doesn't resolve relative files when provisioninig
vagrant up

# Update all machines
for ip in '192.168.100.10' '192.168.100.20' '192.168.100.21'; do
  ssh -t -i "${pwd}/keys/private" -o "StrictHostKeyChecking no" "root@${ip}" "yum update -y && yum install vim net-tools -y"
done

ansible-playbook -i "${pwd}/hosts.local.yaml" "${pwd}/openshift-ansible/playbooks/prerequisites.yml" "$@"
ansible-playbook -i "${pwd}/hosts.local.yaml" "${pwd}/openshift-ansible/playbooks/deploy_cluster.yml" "$@"

ssh -t -i ./keys/private -o "StrictHostKeyChecking no" root@192.168.100.10 <<EOF
  htpasswd -b /etc/origin/master/htpasswd admin admin && oc adm policy add-cluster-role-to-user cluster-admin admin
EOF

# oc login https://master.192.168.100.10.nip.io:8443 admin/admin