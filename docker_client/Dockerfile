# Image base
FROM ubuntu:14.04 

# Update Ubuntu/ mise à jour et mise à niveau des paquets d'Ubuntu
RUN apt-get update && apt-get -y upgrade

# Install Java and Tomcat/ Installer Java et le serveur TomcatCOPCM
RUN apt-get install -y --no-install-recommends openjdk-7-jdk tomcat7

# Install maven/ Installer maven
#RUN apt-get update  
RUN apt-get install -y maven

#To choose a workdir / créer et faire de ce répertoire mon repertoire de travail et y loguer en console
WORKDIR /code

# Install manage Tomcat/ Installer Tomcat7-admin pour administrer Tomcat
RUN apt-get -y install tomcat7-admin

# Expose a port 8080 for host/ exposer le port 8080 à l'exterieur
EXPOSE 8080

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

# Dynamic Environment with ARG/ déclarations des variables d'environnement pour personnaliser le nom du contexte 
#et le goal de Lutèce 
ARG GOAL_LUTECE=lutece:site-assembly
ARG LUTECE=lutece
ENV webapp=plugin-dockerlutece-1.0.0-SNAPSHOT

# Delete targer if exists
# Compile et create target directory/ exécuter le goal de Lutèce pour compiler le projet Lutèce
RUN mvn $GOAL_LUTECE

# Edit file db.properies // Editer le fichier db.properties pour modifier le nom de la BD et le mot de passe
# Edit database address  where we connect with container lutece_cont// Editer l'addresse de la base de donnée que nous avons nous connecter
RUN sed -i 's/lutece/db_lutece/' /code/target/$webapp/WEB-INF/conf/db.properties
RUN sed -i 's/localhost/172.17.0.2/' /code/target/$webapp/WEB-INF/conf/db.properties
RUN sed -i 's/motdepasse/laye/' /code/target/$webapp/WEB-INF/conf/db.properties
RUN sed -i 's/fr.paris.db_lutece.util.pool.service.LuteceConnectionService/fr.paris.lutece.util.pool.service.LuteceConnectionService/' \
/code/target/$webapp/WEB-INF/conf/db.properties

# Edit file build.xml // Editer le fichier build.xml pour pouvoir se connecter pendant l'initialisation avec ant
RUN sed -i '2i <target name="build">' /code/target/$webapp/WEB-INF/sql/build.xml
RUN sed -i '3i   <sshexec ' /code/target/$webapp/WEB-INF/sql/build.xml
RUN sed -i '4i       host="172.17.0.2"' /code/target/$webapp/WEB-INF/sql/build.xml
RUN sed -i '5i       username="root"' /code/target/$webapp/WEB-INF/sql/build.xml
RUN sed -i '6i       password="laye"' /code/target/$webapp/WEB-INF/sql/build.xml
RUN sed -i '7i   />' /code/target/$webapp/WEB-INF/sql/build.xml
RUN sed -i '8i </target>' /code/target/$webapp/WEB-INF/sql/build.xml

# Install mysql client // installer mysql-client pour se connecter au mysql server
RUN apt-get -y install mysql-client

#Edit file create_db_lutece_core.sql/ Editer le fichier create_db_lutece_core.sql pour les erreurs MySQL dû aux valeurs de la clé primaire
# qui ne doivent pas être nulles. de même pour la contraine NOT_DATA_ZERO
RUN sed -i 's/SMALLINT DEFAULT NULL/SMALLINT NOT NULL DEFAULT 0/' /code/target/$webapp/WEB-INF/sql/create_db_lutece_core.sql
RUN sed -i 's/workgroup_key varchar(50) default NULL/workgroup_key varchar(50) NOT NULL/' /code/target/$webapp/WEB-INF/sql/create_db_lutece_core.sql
RUN sed -i 's/id_user int default NULL/id_user int NOT NULL/' /code/target/$webapp/WEB-INF/sql/create_db_lutece_core.sql
RUN sed -i s/"'"0000-00-00" "00:00:00"'"/CURRENT_TIMESTAMP/g /code/target/$webapp/WEB-INF/sql/create_db_lutece_core.sql

# Create database with ant/ créer la base de donnée avec ant
RUN ant -file /code/target/$webapp/WEB-INF/sql/build.xml -v

# Copy directory Lutece to webapp Tomcat / copier le dossier généré dans la WebApp de Tomcat
RUN cp -r /code/target/$webapp /var/lib/tomcat7/webapps/$LUTECE
