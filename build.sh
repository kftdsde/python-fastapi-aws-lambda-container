sudo chmod 777 -R ../kft-credit-scoring

buildtype=${1:-"local"}
echo "Buildtype = $buildtype"

#-----------------------------------------------
#---- Setup necessary ENV variables ------------
#-----------------------------------------------
branch_name=$(git symbolic-ref -q HEAD)
branch_name=${branch_name##refs/heads/}
export branch_name=${branch_name:-HEAD}

if [ $branch_name == "staging" ]; then
    echo "******Running Staging Environment******"
    export yarntarget="develop"
    export NODE_ENV="development"
    export dbname="stagedb"
    export dnsprefix='stage-csengine'
    export fromsuffix='sgage-csengine'
    export tosuffix='stage-csengine'
    export ecrstage='stage-csengine'

elif [ $branch_name == "prod" ]; then
    echo "******Running Production Environment******"
    export yarntarget="start"
    export NODE_ENV="production"
    export dbname="proddb"
    export dnsprefix='csengine'
    export fromsuffix='csengine'
    export tosuffix='csengine'
    export ecrstage='csengine'    
else
    echo "******Running Development Environment******"
    export yarntarget="develop"
    export NODE_ENV="development"
    export dbname="devdb"
    export dnsprefix='dev-csengine'
    export fromsuffix='dev-csengine'
    export tosuffix='dev-csengine'
    export ecrstage='dev-csengine'    
fi

#========================================= 
#       write Dockerfile
#=========================================
if [ $buildtype == "local" ]; then
    echo "Using Dockerfile.local ... "
    name="fapi"
    port=5000
    tport=5000
    cp Dockerfile.local Dockerfile
else
    echo "Using Dockerfile.aws.lambda ... "
    name="fapilambda"
    port=9000
    tport=8080
    cp Dockerfile.aws.lambda Dockerfile    
fi

#=========================================
#       write docker-compose.yml
#=========================================

cat <<EOF > docker-compose.yml
version: "3"
services:
  $name:
    container_name: $name
    build: .
    image: $name:latest
    restart: unless-stopped
    network_mode: "host"
    expose:
      - $tport 
    ports:
      - "$port:$tport"

EOF
    

#-----------------------------------------------
#---- build Strapi CMS ------------
#-----------------------------------------------
res=$(docker ps -aq)
if [ ! -z $res ]; then
    docker rm $res
fi

docker-compose build  $name
docker-compose up --force-recreate -d $name
docker ps


#test
echo "Pinging webserver endpoint: "
curl http://localhost:$port/
echo ""
