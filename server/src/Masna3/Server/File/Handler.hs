module Masna3.Server.File.Handler where

import Data.Aeson
import Data.Text.Encoding qualified as Text
import Effectful
import Effectful.Error.Static qualified as Error
import Effectful.Log qualified as Log
import Effectful.Reader.Static qualified as Reader
import Effectful.Time qualified as Time
import Masna3.Api.File
import Masna3.Api.File.FileId
import Servant.API.ContentTypes

import Masna3.Server.AWS.URL
import Masna3.Server.Database
import Masna3.Server.Effects
import Masna3.Server.Environment
import Masna3.Server.Error
import Masna3.Server.File.Guards
import Masna3.Server.Model.File.Types
import Masna3.Server.Model.File.Update qualified as Update
import Masna3.Server.Model.Process.Types as ProcessTypes
import Masna3.Server.Model.Process.Update qualified as ProcessUpdate
import Masna3.Server.Owner.Guards
import Masna3.Server.Process.Guards

registerHandler :: FileRegistrationForm -> Eff RouteEffects FileRegistrationResult
registerHandler form = do
  Masna3Env{awsBucket} <- Reader.ask
  void $ guardThatOwnerExists form.ownerId
  traverse_ guardThatProcessCompleted form.processId
  file <-
    newFile
      form.ownerId
      form.processId
      form.fileName
      awsBucket
      form.mimeType
  let path = display form.ownerId <> "/" <> display file.fileId <> "/" <> form.fileName
  url <-
    Text.decodeUtf8
      <$> newPutURL
        awsBucket
        form.mimeType
        path
  withPool $ do
    Update.insertFile file
    traverse_ (`ProcessUpdate.updateProcessStatus` ProcessTypes.InProgress) form.processId
  pure FileRegistrationResult{fileId = file.fileId, url, processId = form.processId}

confirmHandler :: FileId -> Eff RouteEffects NoContent
confirmHandler fileId = do
  file <- guardThatFileExists fileId
  case file.status of
    Pending -> do
      timestamp <- Time.currentTime
      withPool (Update.confirmFile fileId timestamp)
      pure NoContent
    _ ->
      Log.localData ["file_id" .= fileId] $
        Error.throwError (InvalidTransition (NotPendingToUploaded (MkInvalidTransitionFile fileId)))

cancelHandler :: FileId -> UploadCancellationForm -> Eff es NoContent
cancelHandler _ _ = pure NoContent

deleteHandler :: FileId -> Eff RouteEffects NoContent
deleteHandler fileId = do
  void $ guardThatFileExists fileId
  withPool (Update.deleteFile fileId)
  pure NoContent
