# Image base
FROM ubuntu:14.04 

# Update Ubuntu/ mise à jour et mise à niveau des paquets d'Ubuntu
RUN apt-get update && apt-get -y upgrade

# Install Java and Tomcat/ Installer Java et le serveur Tomcat
RUN apt-get install -y --no-install-recommends openjdk-7-jdk tomcat7

# Install maven/ Installer maven
#RUN apt-get update  
RUN apt-get install -y maven

#To choose a workdir / créer et faire de ce répertoire mon repertoire de travail et y loguer en console
WORKDIR /code

# To add configurations file of Tomcat/ ajouter les fichiers de configurations relatifs à Tomcat
ADD settings.xml /usr/local/tomcat/conf/
ADD tomcat-users.xml /usr/local/tomcat/conf/

# Install manage Tomcat/ Installer Tomcat7-admin pour administrer Tomcat
RUN apt-get -y install tomcat7-admin

# Expose a port 8080 for host/ exposer le port 8080 à l'exterieur
EXPOSE 8080

#Install mysql server/ Installer la base de donnée MySQL
RUN apt-get -y install mysql-server

# Install ant/ Installer ant pour initialiser la base de donnée de Lutèce
RUN apt-get install ant

# Install supervisor/ Installer supervisor pour démarrer les deamons
RUN apt-get -y install supervisor

# Copy file supervisor.conf / copier le fichier de configuration de supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Prepare by downloading dependencies/ Ajouter le fichier POM 
ADD pom.xml /code/pom.xml

# Adding source// Documenter les 2 lignes pour compiler les sources de Lutèce en ajoutant src et webapp
#ADD src /code/src
#ADD webapp /code/webapp

# Dynamic Environment with ARG/ déclarations des variables d'environnement pour personnaliser le nom du BD, le contexte et le goal de Lutèce 
ARG GOAL_LUTECE=lutece:site-assembly
ARG BD=lutece_bd
ARG LUTECE=lutece_contexte

# Delete targer if exists
# Compile et create target directory/ exécuter le goal de Lutèce pour compiler le projet Lutèce
RUN mvn $GOAL_LUTECE

# Edit file db.properies // Editer le fichier db.properties pour modifier le nom de la BD et le mot de passe
RUN sed -i 's/lutece/$BD/' /code/target/plugin-dockerlutece-1.0.0-SNAPSHOT/WEB-INF/conf/db.properties
RUN sed -i 's/motdepasse//' /code/target/plugin-dockerlutece-1.0.0-SNAPSHOT/WEB-INF/conf/db.properties
RUN sed -i 's/fr.paris.$BD.util.pool.service.LuteceConnectionService/fr.paris.lutece.util.pool.service.LuteceConnectionService/' \
/code/target/plugin-dockerlutece-1.0.0-SNAPSHOT/WEB-INF/conf/db.properties

# Create database with ant/ créer la base de donnée avec ant
RUN /bin/bash -c "/usr/bin/mysqld_safe &" && \
  sleep 5 && \
  ant -file /code/target/plugin-dockerlutece-1.0.0-SNAPSHOT/WEB-INF/sql/build.xml -v

# Copy directory Lutece to webapp Tomcat / copier le dossier généré dans la WebApp de Tomcat
RUN cp -r /code/target/plugin-dockerlutece-1.0.0-SNAPSHOT /var/lib/tomcat7/webapps/$LUTECE

# Exec mysql service and Tomcat service/ exécute le fichier supervisor pour démarrer le service de tomcat et de MySQL
CMD ["/usr/bin/supervisord"]
