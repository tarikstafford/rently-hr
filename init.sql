-- Create horilla role if it doesn't exist
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'horilla') THEN
      CREATE ROLE horilla LOGIN PASSWORD 'horilla';
   END IF;
END
$do$;

-- Create horilla_main database if it doesn't exist
SELECT 'CREATE DATABASE horilla_main OWNER horilla'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'horilla_main')\gexec 