module Masna3.Api.Client
  ( registerFile
  , confirmFile
  , deleteFile
  , registerProcess
  , completeProcess
  , cancelProcess
  ) where

import Data.Proxy
import Servant.API
import Servant.Client

import Masna3.Api
import Masna3.Api.File
import Masna3.Api.File.FileId
import Masna3.Api.Process
import Masna3.Api.Process.ProcessId

masna3Client :: ServerRoutes (AsClientT ClientM)
masna3Client = client (Proxy @(NamedRoutes ServerRoutes))

registerFile :: FileRegistrationForm -> ClientM FileRegistrationResult
registerFile form =
  masna3Client
    // (.api)
    // (.files)
    // (.register)
    /: form

confirmFile :: FileId -> ClientM NoContent
confirmFile fileId =
  masna3Client
    // (.api)
    // (.files)
    // (.confirm)
    /: fileId

deleteFile :: FileId -> ClientM NoContent
deleteFile fileId =
  masna3Client
    // (.api)
    // (.files)
    // (.delete)
    /: fileId

registerProcess :: ProcessRegistrationForm -> ClientM ProcessRegistrationResult
registerProcess form =
  masna3Client
    // (.api)
    // (.processes)
    // (.register)
    /: form

completeProcess :: ProcessId -> ClientM NoContent
completeProcess processId =
  masna3Client
    // (.api)
    // (.processes)
    // (.complete)
    /: processId

cancelProcess :: ProcessId -> ClientM NoContent
cancelProcess processId =
  masna3Client
    // (.api)
    // (.processes)
    // (.cancel)
    /: processId
