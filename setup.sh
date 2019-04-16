!#
#install JDK 8
sudo yum install java-1.8.0-openjdk
sudo yum install java-1.8.0-openjdk-devel

#install docker
sudo yum update
sudo yum install yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce
sudo systemctl start docker
sudo systemctl enable docker
docker -v

#install ELK
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
sudo vi /etc/yum.repos.d/elasticsearch.repo
i
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
^c

sudo yum install elasticsearch
sudo vi /usr/share/elasticsearch/config/elasticsearch.yml
i
cluster.name: crec-demo-cluster
node.name: crec-demo-node
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: localhost
network.port: 9200
^C

sudo yum install kibana
sudo systemctl enable kibana
sudo vi /etc/kibana/kibana.yml
i
server.port: 5601
server.host: "localhost"
server.basePath: ""
server.rewriteBasePath: false
server.name: "crec-demo-host"
elasticsearch.hosts: "http://localhost:9200"
elasticsearch.url: "http://localhost:9200"
elasticsearch.preserveHost: true
kibana.index: ".kibana"
elasticsearch.pingTimeout: 1500
elasticsearch.requestTimeout: 30000
elasticsearch.shardTimeout: 0
elasticsearch.startupTimeout: 5000
pid.file: /var/run/kibana.pid
logging.dest: stdout
logging.silent: false
logging.quiet: false
logging.verbose: false
ops.interval: 50000
i18n.locale: "en"
^C

sudo yum install logstash
sudo vi /etc/logstash/config/logstash.conf
i
input {
  tcp {
    port => 5044
    codec => json
    }
  }

output {
  elasticsearch {
    hosts => ["localhost:9200"]
  }
}
^C

cd ~
sudo mkdir deploy_sim
cd ~/deploy_sim
sudo touch docker-compose.yml
sudo vi ~/deploy_sim/docker-compose.yml
i
version: "2"

services:
  #generate data
  flask_generate:
    image: ianyav1996cesuser/flask_generate:latest
    container_name: ianyav1996cesuser/flask_generate
    ports:
      - 5040:5040
    networks:
      - logging
    links:
      - logstash
  #index, search & agregation
  elasticsearch:
    image elasticsearch:latest
    container_name: elasticsearch
    environment:
      - ES_JAVA_OPTS=-Xms1g -Xmx1g
    ports:
      - 9200:9200
      - 9300:9300
    volumes:
      - $PWD/elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearcch.yml
      - "es-data:/usr/share/elasticsearch/data
    networks:
      - logging
  # GUI
  kibana:
    image: kibana:latest
    container_name: kibana
    ports:
      - 5601:5601
    environment:
      - $PWD/kibana/oconfig/kibana.yml:/etc/kibana/kibana.yml
    networks:
      - logging
    depends_on:
      - elasticsearch
  #indexer
  logstash:
    image: logstash:latest
    container_name: logstash
    command: logstash -f /config/
    environment:
      - JAVA_OPTS=-Xms1g -Xmx1g
    volumes:
      - $PWD/logstash/config/logstash.conf:/etc/logstash/config/logstash.conf
    networks:
      - logging
    depends_on:
      - elasticsearch

volumes:
  es-data:
    driver: local

networks:
  logging:
    driver: bridge
^C

cd ~

# install docker compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

cd ~/deploy_sim
sudo docker-compose up

