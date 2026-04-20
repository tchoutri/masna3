{-# OPTIONS_GHC -Wno-orphans #-}

module Masna3.Server.Model.Process.Types
  ( Status (..)
  , Process (..)
  , newProcess
  ) where

import Data.ByteString.Char8 qualified as BS8
import Data.Time (UTCTime)
import Database.PostgreSQL.Entity
import Database.PostgreSQL.Entity.Types
import Database.PostgreSQL.Simple.FromField
import Database.PostgreSQL.Simple.FromRow hiding (field)
import Database.PostgreSQL.Simple.ToField
import Database.PostgreSQL.Simple.ToRow
import Effectful
import Effectful.Time (Time)
import Effectful.Time qualified as Time
import GHC.Generics
import Masna3.Api.Owner.OwnerId
import Masna3.Api.Process.ProcessId

data Status
  = Started
  | InProgress
  | Completed
  deriving stock (Eq, Generic, Ord, Show)

instance ToField Status where
  toField Started = Escape "started"
  toField InProgress = Escape "in_progress"
  toField Completed = Escape "completed"

instance FromField Status where
  fromField f Nothing = returnError UnexpectedNull f ""
  fromField f (Just bs) =
    case bs of
      "started" -> pure Started
      "in_progress" -> pure InProgress
      "completed" -> pure Completed
      e ->
        returnError ConversionFailed f $
          "Conversion error: Expected valid progress Status for 'status', got: " <> BS8.unpack e

data Process = Process
  { processId :: ProcessId
  , ownerId :: OwnerId
  , status :: Status
  , createdAt :: UTCTime
  , updatedAt :: Maybe UTCTime
  }
  deriving stock (Eq, Generic, Ord, Show)
  deriving anyclass (FromRow, ToRow)
  deriving
    (Entity)
    via (GenericEntity '[TableName "processes"] Process)

newProcess
  :: (IOE :> es, Time :> es)
  => OwnerId
  -> Eff es Process
newProcess ownerId = do
  processId <- newProcessId
  createdAt <- Time.currentTime
  pure
    Process
      { processId
      , ownerId
      , status = Started
      , createdAt
      , updatedAt = Nothing
      }
