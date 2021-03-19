# Install the Kubernetes Resources
helm upgrade --install wth-postgresql ../PostgreSQL116 --set infrastructure.password=OCPHack8

# Get the postgres pod name
$pgPodName=$(kubectl -n postgresql get pods --no-headers -o custom-columns=":metadata.name")

#Copy pg.sql to the postgresql pod
kubectl -n postgresql cp ./pg.sql $pgPodName:/tmp/pg.sql

# Use this to connect to the database server
kubectl -n postgresql exec deploy/postgres -it -- /usr/bin/psql -U postgres -f /tmp/pg.sql

# Install the Kubernetes Resources
helm upgrade --install wth-mysql ../MySQL57 --set infrastructure.password=OCPHack8

# Get the MySQL pod name
$mysqlPodName=$(kubectl -n mysql get pods --no-headers -o custom-columns=":metadata.name")

#Copy mysql.sql to the postgresql pod
kubectl -n mysql cp ./mysql.sql $mysqlPodName:/tmp/mysql.sql

# Use this to connect to the database server

kubectl -n mysql exec deploy/mysql -it -- /usr/bin/mysql -u root -pOCPHack8 < mysql.sql 

cd ../ContosoPizza

$postgresClusterIP=$(kubectl -n postgresql get svc -o json -o json |jq .items[0].spec.clusterIP |tr -d '"')
$mysqlClusterIP=$(kubectl -n mysql get svc -o json -o json |jq .items[0].spec.clusterIP |tr -d '"')

sed "s/XXX.XXX.XXX.XXX/$clusterip/" values-postgres.yaml >temp_mysql.yaml && mv temp_postgres.yaml values-postgres.yaml
sed "s/XXX.XXX.XXX.XXX/$clusterip/" values-mysql.yaml >temp_mysql.yaml && mv temp_mysql.yaml values-mysql.yaml

helm upgrade --install mysql-contosopizza ./ContosoPizza -f ./ContosoPizza/values.yaml -f ./ContosoPizza/values-mysql.yaml

helm upgrade --install postgres-contosopizza ./ContosoPizza -f ./ContosoPizza/values.yaml -f ./ContosoPizza/values-postgresql.yaml

