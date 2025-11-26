module Masna3.Test.File where

import BackgroundJobs.Job qualified as Job
import BackgroundJobs.Poller qualified as Poller
import BackgroundJobs.Queue qualified as Queue
import BackgroundJobs.Worker
import Data.Aeson
import Effectful.Concurrent
import Effectful.Concurrent.Async qualified as Async
import Effectful.Log qualified as Log
import Effectful.Time qualified as Time
import Masna3.Api.Client qualified as Client
import Masna3.Api.File
import Test.Tasty

import Masna3.Server.Jobs.Types
import Masna3.Server.Model.File.Query qualified as Query
import Masna3.Server.Model.File.Types
import Masna3.Server.Model.File.Update qualified as Update
import Masna3.Server.Model.Owner.Types
import Masna3.Server.Model.Owner.Update qualified as Update
import Masna3.Test.Utils

spec :: TestEnv -> TestTree
spec env =
  testGroup
    "File tests"
    [ testThis env "Register file" testRegisterFile
    , testThis env "Confirm File" testConfirmFile
    , testThis env "Confirm File Invalid Transition" testConfirmFileInvalidTransition
    , testThis env "Delete File" testDeleteFile
    , testThis env "Delete File Invalid Transition" testDeleteFileInvalidTransition
    , testThis env "Unconfirmed file gets trashed by background jobs" testUnconfirmedFileGetsTrashed
    ]

testRegisterFile :: TestEff ()
testRegisterFile = do
  owner <- newOwner "test-client"
  withTestPool $ Update.insertOwner owner
  let fileName = "toto.txt"
      mimeType = "text/plain"
  let form = FileRegistrationForm fileName owner.ownerId mimeType
  void $ assertRight "Register file" =<< runRequest (Client.registerFile form)

testConfirmFile :: TestEff ()
testConfirmFile = do
  owner <- newOwner "test-client-2"
  withTestPool $ Update.insertOwner owner
  let fileName = "toto.txt"
      mimeType = "text/plain"
  let form = FileRegistrationForm fileName owner.ownerId mimeType
  result <- assertRight "Register file" =<< runRequest (Client.registerFile form)
  void $ assertRight "Confirm File" =<< runRequest (Client.confirmFile result.fileId)

testConfirmFileInvalidTransition :: TestEff ()
testConfirmFileInvalidTransition = do
  owner <- newOwner "test-client-3"
  withTestPool $ Update.insertOwner owner
  let fileName = "toto.txt"
      mimeType = "text/plain"
  let form = FileRegistrationForm fileName owner.ownerId mimeType
  result <- assertRight "Register file" =<< runRequest (Client.registerFile form)
  void $ assertRight "Confirm File" =<< runRequest (Client.confirmFile result.fileId)
  void $ assertLeftWithStatus "Confirm File" 500 =<< runRequest (Client.confirmFile result.fileId)

testDeleteFile :: TestEff ()
testDeleteFile = do
  owner <- newOwner "test-client-4"
  withTestPool $ Update.insertOwner owner
  let fileName = "toto.txt"
      mimeType = "text/plain"
  let form = FileRegistrationForm fileName owner.ownerId mimeType
  result <- assertRight "Register file" =<< runRequest (Client.registerFile form)
  void $ assertRight "Confirm File" =<< runRequest (Client.confirmFile result.fileId)
  void $ assertRight "Delete File" =<< runRequest (Client.deleteFile result.fileId)

testDeleteFileInvalidTransition :: TestEff ()
testDeleteFileInvalidTransition = do
  owner <- newOwner "test-client-5"
  withTestPool $ Update.insertOwner owner
  let fileName = "toto.txt"
      mimeType = "text/plain"
  let form = FileRegistrationForm fileName owner.ownerId mimeType
  result <- assertRight "Register file" =<< runRequest (Client.registerFile form)
  void $ assertRight "Confirm File" =<< runRequest (Client.confirmFile result.fileId)
  void $ assertRight "Delete File" =<< runRequest (Client.deleteFile result.fileId)
  void $ assertLeftWithStatus "Delete File" 404 =<< runRequest (Client.deleteFile result.fileId)

testUnconfirmedFileGetsTrashed :: TestEff ()
testUnconfirmedFileGetsTrashed = do
  owner <- newOwner "test-client-6"
  let testWorkerConfig =
        workerConfig
          { process = \case
              PurgeExpiredFiles -> do
                now <- Time.currentTime
                files <- Query.listExpiredFiles now
                Log.logInfo "Expired files" $
                  object ["amount" .= length files]
                forM_ files $ \file ->
                  Update.deleteFile file.fileId
          }
  withTestPool $ Update.insertOwner owner
  let fileName = "file-to-delete.txt"
      mimeType = "text/plain"
  let form = FileRegistrationForm fileName owner.ownerId mimeType
  result <- assertRight "Register file" =<< runRequest (Client.registerFile form)

  withTestPool $ do
    Queue.createQueue "masna3_jobs"
    Job.insertJob "masna3_jobs" PurgeExpiredFiles
  Async.race_
    (withTestPool (Poller.monitorQueue pollerConfig testWorkerConfig))
    ( do
        threadDelay 500_000
        r <- withTestPool (Query.getFileById result.fileId)
        case r of
          Nothing -> pure ()
          Just file -> assertFailure $ "Found the file in the files table! " <> show file
    )
