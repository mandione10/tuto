FROM ubuntu:14.04 

# Update Ubuntu
RUN apt-get update && apt-get -y upgrade

# Add oracle java 7 repository
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:webupd8team/java 
RUN apt-get -y update

# Accept the Oracle Java license
RUN echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 boolean true" | debconf-set-selections

# Install Oracle Java
RUN apt-get -y install oracle-java8-installer

# Install maven
RUN apt-get update  
RUN apt-get install -y maven

WORKDIR /code

# Prepare by downloading dependencies
ADD pom.xml /code/pom.xml

# Adding source
ADD src /code/src
ADD webapp /code/webapp
RUN ["mvn", "clean"]
RUN ["mvn", "lutece:exploded"]

# Install tomcat
RUN apt-get -y install tomcat7

RUN echo "JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> /etc/default/tomcat7

ADD settings.xml /usr/local/tomcat/conf/
ADD tomcat-users.xml /usr/local/tomcat/conf/

RUN apt-get -y install tomcat7-docs tomcat7-admin tomcat7-examples
EXPOSE 8080

#-------base de données mysql
RUN apt-get -y install mysql-server mysql-client
RUN /bin/bash -c "/usr/bin/mysqld_safe &" && \
  sleep 5 && \
  mysqladmin -u root -p status && \
  service mysql status
EXPOSE 3306

# Install ant
RUN apt-get install ant

RUN sed -i 's/lutece/lutece_bp/' /code/target/lutece/WEB-INF/conf/db.properties
RUN sed -i 's/motdepasse//' /code/target/lutece/WEB-INF/conf/db.properties
RUN sed -i 's/fr.paris.lutece_bp.util.pool.service.LuteceConnectionService/fr.paris.lutece.util.pool.service.LuteceConnectionService/' /code/target/lutece/WEB-INF/conf/db.properties


RUN /bin/bash -c "/usr/bin/mysqld_safe &" && \
  sleep 5 && \
  ant -file /code/target/lutece/WEB-INF/sql/build.xml -v

RUN cp -r /code/target/lutece /var/lib/tomcat7/webapps/bp

RUN apt-get -y install supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN cat /var/lib/tomcat7/webapps/bp/WEB-INF/conf/db.properties
CMD ["/usr/bin/supervisord"]