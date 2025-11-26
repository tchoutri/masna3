module Masna3.Server.Jobs.Types where

import BackgroundJobs.Poller
import BackgroundJobs.Poller qualified as Poller
import BackgroundJobs.Worker
import Data.Aeson
import Data.Time
import Database.PostgreSQL.Simple.FromField
import Database.PostgreSQL.Simple.Newtypes
import Database.PostgreSQL.Simple.ToField
import Deriving.Aeson
import Effectful
import Effectful.Log (Log)
import Effectful.Log qualified as Log
import Effectful.PostgreSQL.Connection
import Effectful.Time (Time)
import Effectful.Time qualified as Time

import Masna3.Server.Model.File.Query qualified as Query
import Masna3.Server.Model.File.Types
import Masna3.Server.Model.File.Update qualified as Update

data Masna3Job
  = PurgeExpiredFiles
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField, TagSingleConstructors])
          Masna3Job
  deriving
    (FromField, ToField)
    via Aeson Masna3Job

pollerConfig :: Log :> es => PollerConfig (Eff es)
pollerConfig = Poller.mkPollerConfig "masna3_jobs"

workerConfig
  :: ( IOE :> es
     , Log :> es
     , Time :> es
     , WithConnection :> es
     )
  => WorkerConfig (Eff es) Masna3Job
workerConfig =
  WorkerConfig
    { queueName = "masna3_jobs"
    , onException = \j e -> error $ "Caught exception while processing Job \"" <> show j <> "\": " <> show e
    , process = processJob
    }

processJob
  :: ( IOE :> es
     , Log :> es
     , Time :> es
     , WithConnection :> es
     )
  => Masna3Job
  -> Eff es ()
processJob = \case
  PurgeExpiredFiles -> do
    now <- Time.currentTime
    files <- Query.listExpiredFiles ((60 * 60 * 24) `addUTCTime` now)
    Log.logInfo "Expired files" $
      object ["amount" .= length files]
    forM_ files $ \file ->
      Update.deleteFile file.fileId
