{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE QuasiQuotes #-}

module Masna3.Server.Model.Process.Update where

import Database.PostgreSQL.Entity
import Database.PostgreSQL.Simple.SqlQQ (sql)
import Effectful
import Effectful.PostgreSQL
import Effectful.Time (Time)
import Effectful.Time qualified as Time
import Masna3.Api.ArchivedProcess.ArchivedProcessId
import Masna3.Api.Process.ProcessId (ProcessId)

import Masna3.Server.Model.Process.Types

insertProcess :: (IOE :> es, WithConnection :> es) => Process -> Eff es ()
insertProcess process = void $ execute (_insert @Process) process

updateProcessStatus :: (IOE :> es, Time :> es, WithConnection :> es) => ProcessId -> Status -> Eff es ()
updateProcessStatus processId status = do
  timestamp <- Time.currentTime
  void $ execute q (status, timestamp, processId)
  where
    q =
      [sql|
        UPDATE processes SET status = ?, updated_at = ?
        WHERE process_id = ?;
       |]

cancelProcess :: (IOE :> es, Time :> es, WithConnection :> es) => ProcessId -> Eff es ()
cancelProcess processId = do
  timestamp <- Time.currentTime
  archivedProcessId <- newArchivedProcessId
  void $ execute q (processId, processId, archivedProcessId, timestamp)
  where
    q =
      [sql|
        WITH deleted_files AS (
          DELETE FROM files
          WHERE process_id = ?
          RETURNING *
        ),
        deleted_process AS (
          DELETE FROM processes
          WHERE process_id = ?
          AND status IN ('started', 'in_progress')
          RETURNING *
        )
        INSERT INTO archived_processes
          (archived_process_id, created_at, reason, payload)
        SELECT ?, ?, 'cancelled', jsonb_build_object(
          'process', to_jsonb(deleted_process.*),
          'files', jsonb_agg(to_jsonb(deleted_files.*))
        )
        FROM deleted_files, deleted_process
        GROUP BY deleted_process.*;
      |]
