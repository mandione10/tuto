# Image base
FROM mysql
# EDit file my.cnf/ Editer le fichier my.cnf pour configurer le bind à l'adresse 172.17.0.2
RUN	sed -i 's/#bind-address/bind-address/' /etc/mysql/my.cnf
RUN	sed -i 's/127.0.0.1/0.0.0.0/' /etc/mysql/my.cnf
RUN	sed -i 's/0.0.0.0/172.17.0.2/' /etc/mysql/my.cnf
