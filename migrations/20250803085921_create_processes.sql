CREATE TYPE process_status AS ENUM ('started' , 'in_progress', 'completed');

CREATE TABLE processes (
    process_id uuid PRIMARY KEY
  , owner_id uuid REFERENCES owners (owner_id) NOT NULL
  , status process_status NOT NULL
  , created_at timestamptz NOT NULL
  , updated_at timestamptz
);

CREATE INDEX ON processes (status) WHERE status IN ('started', 'in_progress');
