CREATE TYPE process_archival_reason AS ENUM ('cancelled');

CREATE TABLE archived_processes (
    archived_process_id uuid PRIMARY KEY
  , created_at timestamptz NOT NULL
  , reason process_archival_reason NOT NULL
  , payload jsonb NOT NULL
);
