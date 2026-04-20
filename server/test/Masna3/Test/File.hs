module Masna3.Test.File where

import Arbiter.Core qualified as Arb
import Arbiter.Simple qualified as ArbS
import Arbiter.Worker qualified as Worker
import Data.Proxy
import Effectful.Concurrent
import Effectful.Concurrent.Async qualified as Async
import Effectful.Reader.Static qualified as Reader
import Log.Class
import Log.Logger (LoggerEnv (..))
import Masna3.Api.Client qualified as Client
import Masna3.Api.File
import Test.Tasty

import Masna3.Server.Jobs.Types
import Masna3.Server.Model.File.Query qualified as Query
import Masna3.Server.Model.Owner.Types
import Masna3.Server.Model.Owner.Update qualified as Update
import Masna3.Test.Utils

type TestQueue =
  '[ '("file_queue", Masna3Job)
   ]

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
      processId = Nothing
  let form = FileRegistrationForm fileName owner.ownerId mimeType processId
  void $ assertRight "Register file" =<< runRequest (Client.registerFile form)

testConfirmFile :: TestEff ()
testConfirmFile = do
  owner <- newOwner "test-client-2"
  withTestPool $ Update.insertOwner owner
  let fileName = "toto.txt"
      mimeType = "text/plain"
      processId = Nothing
  let form = FileRegistrationForm fileName owner.ownerId mimeType processId
  result <- assertRight "Register file" =<< runRequest (Client.registerFile form)
  void $ assertRight "Confirm File" =<< runRequest (Client.confirmFile result.fileId)

testConfirmFileInvalidTransition :: TestEff ()
testConfirmFileInvalidTransition = do
  owner <- newOwner "test-client-3"
  withTestPool $ Update.insertOwner owner
  let fileName = "toto.txt"
      mimeType = "text/plain"
      processId = Nothing
  let form = FileRegistrationForm fileName owner.ownerId mimeType processId
  result <- assertRight "Register file" =<< runRequest (Client.registerFile form)
  void $ assertRight "Confirm File" =<< runRequest (Client.confirmFile result.fileId)
  void $ assertLeftWithStatus "Confirm File" 500 =<< runRequest (Client.confirmFile result.fileId)

testDeleteFile :: TestEff ()
testDeleteFile = do
  owner <- newOwner "test-client-4"
  withTestPool $ Update.insertOwner owner
  let fileName = "toto.txt"
      mimeType = "text/plain"
      processId = Nothing
  let form = FileRegistrationForm fileName owner.ownerId mimeType processId
  result <- assertRight "Register file" =<< runRequest (Client.registerFile form)
  void $ assertRight "Confirm File" =<< runRequest (Client.confirmFile result.fileId)
  void $ assertRight "Delete File" =<< runRequest (Client.deleteFile result.fileId)

testDeleteFileInvalidTransition :: TestEff ()
testDeleteFileInvalidTransition = do
  owner <- newOwner "test-client-5"
  withTestPool $ Update.insertOwner owner
  let fileName = "toto.txt"
      mimeType = "text/plain"
      processId = Nothing
  let form = FileRegistrationForm fileName owner.ownerId mimeType processId
  result <- assertRight "Register file" =<< runRequest (Client.registerFile form)
  void $ assertRight "Confirm File" =<< runRequest (Client.confirmFile result.fileId)
  void $ assertRight "Delete File" =<< runRequest (Client.deleteFile result.fileId)
  void $ assertLeftWithStatus "Delete File" 404 =<< runRequest (Client.deleteFile result.fileId)

testUnconfirmedFileGetsTrashed :: TestEff ()
testUnconfirmedFileGetsTrashed = do
  env <- Reader.ask
  owner <- newOwner "test-client-6"
  logger <- leLogger <$> getLoggerEnv
  withTestPool $ Update.insertOwner owner
  let fileName = "file-to-delete.txt"
      mimeType = "text/plain"
      processId = Nothing
  let form = FileRegistrationForm fileName owner.ownerId mimeType processId
  result <- assertRight "Register file" =<< runRequest (Client.registerFile form)
  arbiterEnv <- ArbS.createSimpleEnv (Proxy @TestQueue) env.connString "public"
  arbiterWorkerConfig <- Worker.defaultWorkerConfig env.connString 5 (processArbiterJob logger)
  let arbJob = Arb.defaultJob PurgeExpiredFiles
  void $ ArbS.runSimpleDb arbiterEnv (Arb.insertJob arbJob)
  Async.race_
    (liftIO $ ArbS.runSimpleDb arbiterEnv $ Worker.runWorkerPool arbiterWorkerConfig)
    ( do
        threadDelay 500_000
        r <- withTestPool (Query.getFileById result.fileId)
        case r of
          Nothing -> pure ()
          Just file -> assertFailure $ "Found the file in the files table! " <> show file
    )
