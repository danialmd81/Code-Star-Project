-- Create ETL database and user
CREATE DATABASE etl_db;
CREATE USER etl_user WITH PASSWORD 'etl_password';
GRANT ALL PRIVILEGES ON DATABASE etl_db TO etl_user;

-- Create Keycloak database and user
CREATE DATABASE keycloak_db;
CREATE USER keycloak WITH PASSWORD 'keycloak1234';
GRANT ALL PRIVILEGES ON DATABASE keycloak_db TO keycloak;

-- Set up permissions for Keycloak database
\c keycloak_db
GRANT ALL ON SCHEMA public TO keycloak;

-- Set up permissions for ETL database
\c etl_db
GRANT ALL ON SCHEMA public TO etl_user;

CREATE USER postgres_exporter PASSWORD 'exporterpass';
GRANT CONNECT ON DATABASE postgres TO postgres_exporter;
GRANT SELECT ON pg_stat_database TO postgres_exporter;
-- Add more grants as needed for metrics