```
инвентори файл ЗЮХ

[pg_consul]
consul-01 ansible_host=51.250.89.137
consul-02 ansible_host=84.201.175.85
consul-03 ansible_host=51.250.7.230
[pg_consul:vars]
consul_srv_config=yes


[pg_teach]
pg-teach-01 ansible_host=51.250.13.132
pg-teach-02 ansible_host=158.160.37.68
pg-teach-03 ansible_host=51.250.91.170

[pg_app]
pg-teach-app ansible_host=158.160.52.149


-- плейбук для развёртывания кластера консула

> consul-playbook.yml - развёрнтывание кластера консул

- hosts: pg_consul
  become: yes
  become_method: sudo
  become_user: root
  roles:
    - ../ROLES/CONSUL

развёртываем командой
export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -u aslepov -i /home/aslepov/aslepov_repo/pgdb_teach/project/yc/playbook_start/hosts consul-playbook.yml -e "permit_root_login=yes"
