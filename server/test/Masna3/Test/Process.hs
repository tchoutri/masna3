module Masna3.Test.Process where

import Masna3.Api.Client qualified as Client
import Masna3.Api.File
import Masna3.Api.Process
import Test.Tasty

import Masna3.Server.Model.Owner.Types
import Masna3.Server.Model.Owner.Update qualified as OwnerUpdate
import Masna3.Server.Model.Process.Query qualified as ProcessQuery
import Masna3.Test.Utils

spec :: TestEnv -> TestTree
spec env =
  testGroup
    "Process tests"
    [ testThis env "Register process" testRegisterProcess
    , testThis env "Complete process invalid transition" testCompleteProcessNoFilesInvalidTransition
    , testThis env "Cancel process" testCancelProcessNoFiles
    , testThis env "Cancel process invalid transition" testCancelProcessNoFilesInvalidTransition
    , testThis env "Complete process with 1 file" testCompleteProcessWith1File
    , testThis env "Complete process with 2 files" testCompleteProcessWith2Files
    , testThis env "Cancel process with 1 file" testCancelProcessWith1File
    , testThis env "Cancel process with 2 files" testCancelProcessWith2Files
    , testThis env "Has unconfirmed files pending" testHasUnconfirmedFilesPending
    , testThis env "Has unconfirmed files completed" testHasUnconfirmedFilesCompleted
    ]

testRegisterProcess :: TestEff ()
testRegisterProcess = do
  owner <- newOwner "test-client-proc-1"
  withTestPool $ OwnerUpdate.insertOwner owner
  let ownerId = owner.ownerId
  let form = ProcessRegistrationForm ownerId
  void $ assertRight "Register process" =<< runRequest (Client.registerProcess form)

testCompleteProcessNoFilesInvalidTransition :: TestEff ()
testCompleteProcessNoFilesInvalidTransition = do
  owner <- newOwner "test-client-proc-2"
  withTestPool $ OwnerUpdate.insertOwner owner
  let ownerId = owner.ownerId
  let form = ProcessRegistrationForm ownerId
  result <- assertRight "Register process" =<< runRequest (Client.registerProcess form)
  void $ assertLeftWithStatus "Complete process" 500 =<< runRequest (Client.completeProcess result.processId)

testCancelProcessNoFiles :: TestEff ()
testCancelProcessNoFiles = do
  owner <- newOwner "test-client-proc-4"
  withTestPool $ OwnerUpdate.insertOwner owner
  let ownerId = owner.ownerId
  let form = ProcessRegistrationForm ownerId
  result <- assertRight "Register process" =<< runRequest (Client.registerProcess form)
  void $ assertRight "Cancel process" =<< runRequest (Client.cancelProcess result.processId)

testCancelProcessNoFilesInvalidTransition :: TestEff ()
testCancelProcessNoFilesInvalidTransition = do
  owner <- newOwner "test-client-proc-5"
  withTestPool $ OwnerUpdate.insertOwner owner
  let ownerId = owner.ownerId
  let form = ProcessRegistrationForm ownerId
  result <- assertRight "Register process" =<< runRequest (Client.registerProcess form)
  void $ assertRight "Cancel process" =<< runRequest (Client.cancelProcess result.processId)
  void $ assertLeftWithStatus "Cancel process" 404 =<< runRequest (Client.cancelProcess result.processId)

testCompleteProcessWith1File :: TestEff ()
testCompleteProcessWith1File = do
  owner <- newOwner "test-client-proc-6"
  withTestPool $ OwnerUpdate.insertOwner owner
  let ownerId = owner.ownerId
  let processForm = ProcessRegistrationForm ownerId
  registerProcessResult <- assertRight "Register process" =<< runRequest (Client.registerProcess processForm)
  let fileName = "toto.txt"
      mimeType = "text/plain"
      processId = Just registerProcessResult.processId
  let fileForm = FileRegistrationForm fileName owner.ownerId mimeType processId
  registerFileResult <- assertRight "Register file" =<< runRequest (Client.registerFile fileForm)
  void $ assertRight "Confirm file" =<< runRequest (Client.confirmFile registerFileResult.fileId)
  void $ assertRight "Complete process" =<< runRequest (Client.completeProcess registerProcessResult.processId)

testCompleteProcessWith2Files :: TestEff ()
testCompleteProcessWith2Files = do
  owner <- newOwner "test-client-proc-7"
  withTestPool $ OwnerUpdate.insertOwner owner
  let ownerId = owner.ownerId
  let processForm = ProcessRegistrationForm ownerId
  registerProcessResult <- assertRight "Register process" =<< runRequest (Client.registerProcess processForm)
  let fileName = "toto.txt"
      mimeType = "text/plain"
      processId = Just registerProcessResult.processId
  let fileForm = FileRegistrationForm fileName owner.ownerId mimeType processId
  registerFileResult <- assertRight "Register file" =<< runRequest (Client.registerFile fileForm)
  registerFileResult2 <- assertRight "Register file" =<< runRequest (Client.registerFile fileForm)
  void $ assertRight "Confirm file" =<< runRequest (Client.confirmFile registerFileResult.fileId)
  void $ assertRight "Confirm file " =<< runRequest (Client.confirmFile registerFileResult2.fileId)
  void $ assertRight "Complete process" =<< runRequest (Client.completeProcess registerProcessResult.processId)

testCancelProcessWith1File :: TestEff ()
testCancelProcessWith1File = do
  owner <- newOwner "test-client-proc-8"
  withTestPool $ OwnerUpdate.insertOwner owner
  let ownerId = owner.ownerId
  let processForm = ProcessRegistrationForm ownerId
  registerProcessResult <- assertRight "Register process" =<< runRequest (Client.registerProcess processForm)
  let fileName = "toto.txt"
      mimeType = "text/plain"
      processId = Just registerProcessResult.processId
  let fileForm = FileRegistrationForm fileName owner.ownerId mimeType processId
  registerFileResult <- assertRight "Register file" =<< runRequest (Client.registerFile fileForm)
  void $ assertRight "Confirm file" =<< runRequest (Client.confirmFile registerFileResult.fileId)
  void $ assertRight "Cancel process" =<< runRequest (Client.cancelProcess registerProcessResult.processId)

testCancelProcessWith2Files :: TestEff ()
testCancelProcessWith2Files = do
  owner <- newOwner "test-client-proc-9"
  withTestPool $ OwnerUpdate.insertOwner owner
  let ownerId = owner.ownerId
  let processForm = ProcessRegistrationForm ownerId
  registerProcessResult <- assertRight "Register process" =<< runRequest (Client.registerProcess processForm)
  let fileName = "toto.txt"
      mimeType = "text/plain"
      processId = Just registerProcessResult.processId
  let fileForm = FileRegistrationForm fileName owner.ownerId mimeType processId
  registerFileResult <- assertRight "Register file" =<< runRequest (Client.registerFile fileForm)
  registerFileResult2 <- assertRight "Register file" =<< runRequest (Client.registerFile fileForm)
  void $ assertRight "Confirm file" =<< runRequest (Client.confirmFile registerFileResult.fileId)
  void $ assertRight "Confirm file " =<< runRequest (Client.confirmFile registerFileResult2.fileId)
  void $ assertRight "Cancel process" =<< runRequest (Client.cancelProcess registerProcessResult.processId)

testHasUnconfirmedFilesPending :: TestEff ()
testHasUnconfirmedFilesPending = do
  owner <- newOwner "test-client-proc-10"
  withTestPool $ OwnerUpdate.insertOwner owner
  let ownerId = owner.ownerId
  let processForm = ProcessRegistrationForm ownerId
  registerProcessResult <- assertRight "Register process" =<< runRequest (Client.registerProcess processForm)
  let fileName = "toto.txt"
      mimeType = "text/plain"
      processId = Just registerProcessResult.processId
  let fileForm = FileRegistrationForm fileName owner.ownerId mimeType processId
  registerFileResult <- assertRight "Register file" =<< runRequest (Client.registerFile fileForm)
  void $ assertRight "Register file" =<< runRequest (Client.registerFile fileForm)
  void $ assertRight "Confirm file" =<< runRequest (Client.confirmFile registerFileResult.fileId)
  result <- withTestPool $ ProcessQuery.hasUnconfirmedFiles registerProcessResult.processId
  assertBool "Should have unconfirmed files" result

testHasUnconfirmedFilesCompleted :: TestEff ()
testHasUnconfirmedFilesCompleted = do
  owner <- newOwner "test-client-proc-11"
  withTestPool $ OwnerUpdate.insertOwner owner
  let ownerId = owner.ownerId
  let processForm = ProcessRegistrationForm ownerId
  registerProcessResult <- assertRight "Register process" =<< runRequest (Client.registerProcess processForm)
  let fileName = "toto.txt"
      mimeType = "text/plain"
      processId = Just registerProcessResult.processId
  let fileForm = FileRegistrationForm fileName owner.ownerId mimeType processId
  registerFileResult <- assertRight "Register file" =<< runRequest (Client.registerFile fileForm)
  registerFileResult2 <- assertRight "Register file" =<< runRequest (Client.registerFile fileForm)
  void $ assertRight "Confirm file" =<< runRequest (Client.confirmFile registerFileResult.fileId)
  void $ assertRight "Confirm file" =<< runRequest (Client.confirmFile registerFileResult2.fileId)
  result <- withTestPool $ ProcessQuery.hasUnconfirmedFiles registerProcessResult.processId
  assertBool "Should have unconfirmed files" (not result)
