export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -u aslepov -i /home/aslepov/aslepov_repo/pgdb_teach/project/yc/playbook_start/hosts consul-playbook.yml -e "permit_root_login=yes"


