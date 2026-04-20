{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE QuasiQuotes #-}

module Masna3.Server.Model.Process.Query
  ( getProcessById
  , getLiveProcessById
  , hasUnconfirmedFiles
  ) where

import Database.PostgreSQL.Entity
import Database.PostgreSQL.Entity.Internal.QQ
import Database.PostgreSQL.Simple.SqlQQ (sql)
import Database.PostgreSQL.Simple.Types
import Effectful
import Effectful.PostgreSQL
import Masna3.Api.Process.ProcessId

import Masna3.Server.Model.File.Query (queryOne)
import Masna3.Server.Model.Process.Types

getProcessById :: (IOE :> es, WithConnection :> es) => ProcessId -> Eff es (Maybe Process)
getProcessById processId = queryOne (_selectWhere @Process [[field| process_id |]]) (Only processId)

getLiveProcessById :: (IOE :> es, WithConnection :> es) => ProcessId -> Eff es (Maybe Process)
getLiveProcessById processId =
  queryOne
    [sql|
  SELECT * FROM processes
  WHERE process_id = ?
  AND status IN ('started', 'in_progress')
  |]
    (Only processId)

hasUnconfirmedFiles :: (IOE :> es, WithConnection :> es) => ProcessId -> Eff es Bool
hasUnconfirmedFiles processId = do
  result <- query q (Only processId)
  pure $ maybe False fromOnly (listToMaybe result)
  where
    q =
      [sql|
          SELECT EXISTS (
            SELECT *
            FROM files
            WHERE process_id = ?
              AND status = 'pending'
          )
        |]
