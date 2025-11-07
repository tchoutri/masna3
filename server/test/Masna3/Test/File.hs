{-# LANGUAGE OverloadedLists #-}

module Masna3.Test.File where

import Masna3.Api.Client qualified as Client
import Masna3.Api.File
import Test.Tasty

import Masna3.Server.Model.Owner.Types
import Masna3.Server.Model.Owner.Update qualified as Update
import Masna3.Test.StructuredOutput
import Masna3.Test.Utils

spec :: TestEnv -> TestTree
spec env =
  testGroup
    "File tests"
    [ testThis env "Register file" testRegisterFile
    , testThis env "Confirm File" testConfirmFile
    , testThis env "Confirm File Invalid Transition" testConfirmFileInvalidTransition
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
  setHeader ["Operation", "Status"]
  owner <- newOwner "test-client-3"
  withTestPool $ Update.insertOwner owner
  let fileName = "toto.txt"
      mimeType = "text/plain"
  let form = FileRegistrationForm fileName owner.ownerId mimeType
  result <- assertRight "Register file" =<< runRequest (Client.registerFile form)
  do
    void $ assertRight "Confirm File" =<< runRequest (Client.confirmFile result.fileId)
    addRow ["Confirm file", "✅"]
  do
    assertLeftWithStatus "Confirm File" 500 =<< runRequest (Client.confirmFile result.fileId)
    addRow ["Double-confirm file", "❌"]
