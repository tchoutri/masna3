{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE QuasiQuotes #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Masna3.Server.Model.File.Types
  ( Status (..)
  , File (..)
  , newFile
  ) where

import Amazonka.S3.Internal (BucketName (..))
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
import Masna3.Api.File.FileId
import Masna3.Api.Owner.OwnerId
import Masna3.Api.Process.ProcessId

data Status
  = Pending
  | Uploaded UTCTime
  deriving stock (Eq, Generic, Ord, Show)

data File = File
  { fileId :: FileId
  , ownerId :: OwnerId
  , processId :: Maybe ProcessId
  , filename :: Text
  , path :: Text
  , status :: Status
  , bucket :: BucketName
  , mimetype :: Text
  , createdAt :: UTCTime
  , updatedAt :: Maybe UTCTime
  }
  deriving stock (Eq, Generic, Ord, Show)

instance Entity File where
  tableName = "files"
  primaryKey = [field| file_id |]
  fields =
    [ [field| file_id |]
    , [field| owner_id |]
    , [field| process_id |]
    , [field| filename |]
    , [field| path |]
    , [field| status |]
    , [field| bucket |]
    , [field| mimetype |]
    , [field| created_at |]
    , [field| updated_at |]
    , [field| uploaded_at |]
    ]

instance ToRow File where
  toRow File{..} =
    let (status', uploadedAt) =
          case status of
            Pending -> (Pending', Nothing)
            Uploaded timestamp -> (Uploaded', Just timestamp)
     in toRow File'{..}

instance FromRow File where
  fromRow = do
    File'{..} <- fromRow
    status <- case (status', uploadedAt) of
      (Pending', Nothing) -> pure Pending
      (Uploaded', Just timestamp) -> pure $ Uploaded timestamp
      _ -> error $ "Inconsistent status: " <> show (status', uploadedAt)
    pure File{..}

deriving via Text instance FromField BucketName
deriving via Text instance ToField BucketName

newFile
  :: (IOE :> es, Time :> es)
  => OwnerId
  -- ^ Owner
  -> Maybe ProcessId
  -- ^ Maybe Process
  -> Text
  -- ^ File name
  -> BucketName
  -- ^ Bucket
  -> Text
  -- ^ MIME type
  -> Eff es File
newFile ownerId processId filename bucket mimetype = do
  fileId <- newFileId
  createdAt <- Time.currentTime
  let path = display ownerId <> "/" <> display fileId <> "/" <> filename
  pure
    File
      { fileId
      , ownerId
      , processId
      , filename
      , path
      , status = Pending
      , bucket
      , mimetype
      , createdAt
      , updatedAt = Nothing
      }

-- Data Access Object
data Status'
  = Pending'
  | Uploaded'
  deriving stock (Eq, Ord, Show)

instance ToField Status' where
  toField Pending' = Escape "pending"
  toField Uploaded' = Escape "uploaded"

instance FromField Status' where
  fromField f Nothing = returnError UnexpectedNull f ""
  fromField f (Just bs) =
    case bs of
      "pending" -> pure Pending'
      "uploaded" -> pure Uploaded'
      e ->
        returnError ConversionFailed f $
          "Conversion error: Expected valid file Status for 'status', got: " <> BS8.unpack e

-- Data Access Object
data File' = File'
  { fileId :: FileId
  , ownerId :: OwnerId
  , processId :: Maybe ProcessId
  , filename :: Text
  , path :: Text
  , status' :: Status'
  , bucket :: BucketName
  , mimetype :: Text
  , createdAt :: UTCTime
  , updatedAt :: Maybe UTCTime
  , uploadedAt :: Maybe UTCTime
  }
  deriving stock (Eq, Generic, Ord, Show)
  deriving anyclass (FromRow, ToRow)
