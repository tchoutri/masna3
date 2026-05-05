module Masna3.Server.File.Guards where

import Data.Aeson
import Effectful
import Effectful.Error.Static (Error)
import Effectful.Error.Static qualified as Error
import Effectful.Log (Log)
import Effectful.Log qualified as Log
import Effectful.Reader.Static (Reader)
import Effectful.Reader.Static qualified as Reader
import Masna3.Api.File.FileId (FileId)

import Masna3.Database
import Masna3.Server.Environment (Masna3Env (..))
import Masna3.Server.Error
import Masna3.Server.Model.File.Query qualified as Query
import Masna3.Server.Model.File.Types

guardThatFileExists
  :: ( Error Masna3Error :> es
     , IOE :> es
     , Log :> es
     , Reader Masna3Env :> es
     )
  => FileId -> Eff es File
guardThatFileExists fileId = do
  Masna3Env{pool} <- Reader.ask
  maybeFile <- withReadOnlyPool pool (Query.getFileById fileId)
  case maybeFile of
    Nothing ->
      Log.localData ["file_id" .= fileId] $
        Error.throwError (FileNotFoundError (FileNotFound fileId))
    Just file -> pure file
