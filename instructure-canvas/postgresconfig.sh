#!/bin/bash

# Get the PostgreSQL version
PG_VERSION=$(psql --version | awk '{print $3}' | cut -d. -f1)

# Configure PostgreSQL to listen on all interfaces
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$PG_VERSION/main/postgresql.conf

# Allow connections from any IP (adjust as needed for security)
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/$PG_VERSION/main/pg_hba.conf

# Restart PostgreSQL to apply changes
sudo systemctl restart postgresql

# Set up a new database and user (change these as needed)
DB_NAME="mydb"
DB_USER="myuser"
DB_PASS="mypassword"

# Create a new database and user
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# Allow PostgreSQL through the firewall
sudo ufw allow 5432/tcp

# Print connection information
echo "PostgreSQL setup complete!"
echo "You can now connect to the database using:"
echo "Host: $(curl -s ifconfig.me)"
echo "Port: 5432"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Password: $DB_PASS"