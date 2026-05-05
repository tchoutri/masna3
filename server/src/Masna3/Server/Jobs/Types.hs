module Masna3.Server.Jobs.Types where

import Arbiter.Core qualified as Arb
import Arbiter.Simple qualified as ArbS
import Data.Aeson
import Data.Pool (Pool)
import Data.Time (UTCTime)
import Database.PostgreSQL.Simple qualified as PG
import Database.PostgreSQL.Simple.FromField
import Database.PostgreSQL.Simple.Newtypes
import Database.PostgreSQL.Simple.ToField
import Deriving.Aeson
import Effectful
import Effectful.Labeled
import Effectful.Log (Log)
import Effectful.Log qualified as Log
import Effectful.PostgreSQL.Connection
import Effectful.Time (Time)
import Effectful.Time qualified as Time

import Masna3.Database
import Masna3.Server.Model.File.Query qualified as Query
import Masna3.Server.Model.File.Types
import Masna3.Server.Model.File.Update qualified as Update

type AppRegistry =
  '[ '("file_queue", Masna3Job)
   ]

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

insertDelayedJob
  :: MonadUnliftIO m
  => ArbS.SimpleEnv AppRegistry
  -> UTCTime
  -> Masna3Job
  -> m (Maybe (Arb.JobRead Masna3Job))
insertDelayedJob env time masna3Job = ArbS.runSimpleDb env $ do
  let arbJob = Arb.defaultJob masna3Job
  Arb.insertJob (arbJob{Arb.notVisibleUntil = Just time})

processArbiterJob
  :: Pool PG.Connection
  -> Log.Logger
  -> Arb.JobHandler (ArbS.SimpleDb AppRegistry IO) Masna3Job ()
processArbiterJob pool logger conn job = do
  liftIO
    . runEff
    . Log.runLog "background-jobs" logger Log.defaultLogLevel
    . Time.runTime
    . runLabeled @ReadOnly (runWithConnection conn)
    $ processJob pool (Arb.payload job)

processJob
  :: ( IOE :> es
     , Labeled ReadOnly WithConnection :> es
     , Log :> es
     , Time :> es
     )
  => Pool PG.Connection
  -> Masna3Job
  -> Eff es ()
processJob pool = \case
  PurgeExpiredFiles -> do
    now <- Time.currentTime
    files <- Query.listExpiredFiles now
    Log.logInfo "Expired files" $
      object ["amount" .= length files]
    forM_ files $ \file ->
      withReadWritePool pool $ Update.deleteFile file.fileId
