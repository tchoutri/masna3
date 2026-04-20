CREATE TYPE file_archival_reason AS ENUM ('deleted' , 'cancelled');

CREATE TABLE archived_files (
    archived_file_id uuid PRIMARY KEY
  , created_at timestamptz NOT NULL
  , reason file_archival_reason NOT NULL
  , payload jsonb NOT NULL
);
