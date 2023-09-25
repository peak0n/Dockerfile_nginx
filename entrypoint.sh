#!/bin/bash

# Wait for the MySQL server to be available (replace with your MySQL host and port)
while ! nc -z -v -w5 $MYSQL_HOST $MYSQL_PORT; do
  echo "Waiting for MySQL server to be available..."
  sleep 5
done

# Configure Moodle's config.php
cat <<EOF > /var/www/html/config.php
<?php
$CFG->dbtype    = 'mysqli';
$CFG->dblibrary = 'native';
$CFG->dbhost    = '$MYSQL_HOST:$MYSQL_PORT'; // Use environment variables
$CFG->dbname    = '$MYSQL_DB';
$CFG->dbuser    = '$MYSQL_USER';
$CFG->dbpass    = '$MYSQL_PASSWORD';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array(
  'dbpersist' => false,
  'dbport'    => '',
  'dbsocket'  => '',
);
$CFG->wwwroot   = 'http://*'; // Replace with your Moodle URL
$CFG->dataroot  = '/var/moodledata';
$CFG->admin     = 'admin';

require_once(__DIR__ . '/lib/setup.php');

// There may be additional Moodle configuration settings here
EOF

# Start your web server (e.g., Apache or Nginx)
# For Apache:
# /usr/sbin/apache2ctl -D FOREGROUND

# For Nginx:
# exec nginx -g "daemon off;"
