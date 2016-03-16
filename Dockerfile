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

#To choose a workdir 
WORKDIR /code

# Prepare by downloading dependencies
ADD pom.xml /code/pom.xml

# Adding source
ADD src /code/src
ADD webapp /code/webapp

# Dynamic Environment with ARG
ARG goal_clean=clean
ARG goal_lutece=lutece:exploded

# Delete targer if exists
# Compile et create target directory
RUN mvn $goal_clean
RUN mvn $goal_lutece

# Install tomcat
RUN apt-get -y install tomcat7

# Configure Tomcat with Java
RUN echo "JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> /etc/default/tomcat7

# To add configurations file of Tomcat
ADD settings.xml /usr/local/tomcat/conf/
ADD tomcat-users.xml /usr/local/tomcat/conf/

# Install manage Tomcat
RUN apt-get -y install tomcat7-docs tomcat7-admin tomcat7-examples

# Expose a port 8080 for host
EXPOSE 8080

#-------base de données mysql
RUN apt-get -y install mysql-server mysql-client
RUN /bin/bash -c "/usr/bin/mysqld_safe &" && \
  sleep 5 && \
  mysqladmin -u root -p status && \
  service mysql status
  
# Expose a port 3306 for host
EXPOSE 3306

# Install ant
RUN apt-get install ant

# Edit file db.properies 
RUN sed -i 's/lutece/lutece_bp/' /code/target/lutece/WEB-INF/conf/db.properties
RUN sed -i 's/motdepasse//' /code/target/lutece/WEB-INF/conf/db.properties
RUN sed -i 's/fr.paris.lutece_bp.util.pool.service.LuteceConnectionService/fr.paris.lutece.util.pool.service.LuteceConnectionService/' /code/target/lutece/WEB-INF/conf/db.properties

# Create database with ant
RUN /bin/bash -c "/usr/bin/mysqld_safe &" && \
  sleep 5 && \
  ant -file /code/target/lutece/WEB-INF/sql/build.xml -v

# Copy directory Lutece to webapp Tomcat 
RUN cp -r /code/target/lutece /var/lib/tomcat7/webapps/bp

# Install supervisor
RUN apt-get -y install supervisor

# Copy file supervisor.conf 
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Exec mysql service and Tomcat service
CMD ["/usr/bin/supervisord"]