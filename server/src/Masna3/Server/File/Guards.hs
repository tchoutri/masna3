module Masna3.Server.File.Guards where

import Data.Aeson
import Effectful
import Effectful.Error.Static qualified as Error
import Effectful.Log qualified as Log
import Masna3.Api.File.FileId (FileId)

import Masna3.Server.Database
import Masna3.Server.Effects
import Masna3.Server.Error
import Masna3.Server.Model.File.Query
import Masna3.Server.Model.File.Types

guardThatFileExists :: FileId -> Eff RouteEffects File
guardThatFileExists fileId = do
  maybeFile <- withPool (getFileById fileId)
  case maybeFile of
    Nothing ->
      Log.localData ["file_id" .= fileId] $
        Error.throwError (FileNotFoundError (FileNotFound fileId))
    Just file -> pure file
