{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE QuasiQuotes #-}

module Masna3.Server.Model.File.Query
  ( getFileById
  , listExpiredFiles
  , queryOne
  ) where

import Data.Set (Set)
import Data.Set qualified as Set
import Data.Time (UTCTime)
import Database.PostgreSQL.Entity
import Database.PostgreSQL.Entity.Internal.QQ
import Database.PostgreSQL.Simple.FromRow (FromRow (..))
import Database.PostgreSQL.Simple.SqlQQ (sql)
import Database.PostgreSQL.Simple.ToRow (ToRow (..))
import Database.PostgreSQL.Simple.Types
import Effectful
import Effectful.PostgreSQL
import GHC.Stack
import Masna3.Api.File.FileId

import Masna3.Server.Model.File.Types

getFileById :: (IOE :> es, WithConnection :> es) => FileId -> Eff es (Maybe File)
getFileById fileId = queryOne (_selectWhere @File [[field| file_id |]]) (Only fileId)

listExpiredFiles
  :: (IOE :> es, WithConnection :> es)
  => UTCTime
  -> Eff es (Set File)
listExpiredFiles timestamp = do
  result <- query q (Only timestamp)
  pure $ Set.fromList result
  where
    q =
      [sql|
          SELECT file_id
               , owner_id
               , process_id
               , filename
               , path
               , status
               , bucket
               , mimetype
               , created_at
               , updated_at
               , uploaded_at
          FROM files
          WHERE created_at <= ?
            AND uploaded_at IS NULL
        |]

queryOne
  :: (FromRow result, HasCallStack, IOE :> es, ToRow params, WithConnection :> es)
  => Query
  -> params
  -> Eff es (Maybe result)
queryOne q params = listToMaybe <$> query q params
