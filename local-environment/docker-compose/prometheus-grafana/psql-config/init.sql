-- To use IF statements, hence to be able to check if the user exists before
-- attempting creation, we need to switch to procedural SQL (PL/pgSQL)
-- instead of standard SQL.
-- More: https://www.postgresql.org/docs/9.3/plpgsql-overview.html
-- To preserve compatibility with <9.0, DO blocks are not used; instead,
-- a function is created and dropped.
CREATE OR REPLACE FUNCTION __tmp_create_user() returns void as $$
BEGIN
  IF NOT EXISTS (
          SELECT                       -- SELECT list can stay empty for this
          FROM   pg_catalog.pg_user
          WHERE  usename = 'postgres_exporter') THEN
    CREATE USER postgres_exporter;
  END IF;
END;
$$ language plpgsql;

SELECT __tmp_create_user();
DROP FUNCTION __tmp_create_user();

ALTER USER postgres_exporter WITH PASSWORD 'prom123';
ALTER USER postgres_exporter SET SEARCH_PATH TO postgres_exporter,pg_catalog;
-- THere is another way if you don't want to use postgres_exporter as a superuser
-- You can tell the exporter to not run all the queries using this parameter here
-- create a file named 
-- psql-config/queries.yaml:
--    | disable_default_metrics: true
-- mount it:
--    | - ./psql-config/queries.yaml:/cfg/queries.yaml
-- And modify the command to:
--    | --config.file=/cnf/postgres_exporter.yml --extend.query-path=/cfg/queries.yaml
ALTER USER postgres_exporter WITH SUPERUSER;

-- If deploying as non-superuser (for example in AWS RDS), uncomment the GRANT
-- line below and replace <MASTER_USER> with your root user.
-- GRANT postgres_exporter TO <MASTER_USER>;

GRANT CONNECT ON DATABASE postgres TO postgres_exporter;