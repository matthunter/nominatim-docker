OSMFILE=$1
PGDIR=$2
THREADS=$3

mkdir -p /data/$PGDIR && \

chown postgres:postgres /data/$PGDIR && \

export  PGDATA=/data/$PGDIR  && \
sudo -u postgres /usr/lib/postgresql/9.5/bin/initdb -D /data/$PGDIR && \
sudo -u postgres /usr/lib/postgresql/9.5/bin/pg_ctl -D /data/$PGDIR start && \
sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='nominatim'" | grep -q 1 || sudo -u postgres createuser -s nominatim && \
sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='www-data'" | grep -q 1 || sudo -u postgres createuser -SDR www-data && \
sudo -u postgres psql postgres -c "DROP DATABASE IF EXISTS nominatim" && \
useradd -m -p password1234 nominatim && \
chown -R nominatim:nominatim ./src && \
sudo -u nominatim ./src/build/utils/setup.php --osm-file $OSMFILE --all --threads $THREADS && \
echo "STARTING PARSING TIGER DATA" && \
sudo -u nominatim ./src/build/utils/imports.php --parse-tiger /data/tiger && \
echo "PARSE COMPLETE" && \
echo "STARTING IMPORT OF TIGER DATA" && \
sudo -u nominatim ./src/build/utils/setup.php --import-tiger-data && \
echo "IMPORTED TIGER DATA" && \
sudo -u nominatim ./src/build/utils/setup.php --create-functions --enable-diff-updates --create-partition-functions && \ 
echo "FINISHED FUNCTION UPDATES" && \
sudo -u postgres psql postgres -tAc "CREATE INDEX nodes_index ON public.planet_osm_ways USING gin (nodes);" 
sudo -u postgres /usr/lib/postgresql/9.5/bin/pg_ctl -D /data/$PGDIR stop && \
sudo chown -R postgres:postgres /data/$PGDIR
