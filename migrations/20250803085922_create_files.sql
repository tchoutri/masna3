CREATE TYPE file_status AS ENUM ('pending' , 'uploaded');

CREATE TABLE files (
    file_id uuid PRIMARY KEY
  , owner_id uuid REFERENCES owners (owner_id) NOT NULL
  , process_id uuid REFERENCES processes (process_id) ON DELETE CASCADE
  , filename text NOT NULL
  , path text NOT NULL
  , status file_status NOT NULL
  , bucket text NOT NULL
  , mimetype text NOT NULL
  , created_at timestamptz NOT NULL
  , updated_at timestamptz
  , uploaded_at timestamptz
  , CONSTRAINT unique_path_by_bucket UNIQUE (bucket, path)
  , CONSTRAINT uploaded_at_status
        CHECK (
            (status = 'pending' AND uploaded_at IS NULL)
         OR (status = 'uploaded' AND uploaded_at IS NOT NULL))
);

CREATE INDEX files_owner_id_fkey ON files (owner_id);

CREATE INDEX files_status_idx ON files (status);
