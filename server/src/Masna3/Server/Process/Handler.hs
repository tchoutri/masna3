module Masna3.Server.Process.Handler where

import Effectful
import Effectful.Reader.Static qualified as Reader
import Masna3.Api.Process
import Masna3.Api.Process.ProcessId (ProcessId)
import Servant.API.ContentTypes

import Masna3.Database
import Masna3.Server.Effects
import Masna3.Server.Environment (Masna3Env (..))
import Masna3.Server.Model.Process.Types
import Masna3.Server.Model.Process.Update qualified as Update
import Masna3.Server.Owner.Guards
import Masna3.Server.Process.Guards

registerHandler :: ProcessRegistrationForm -> Eff RouteEffects ProcessRegistrationResult
registerHandler form = do
  Masna3Env{pool} <- Reader.ask
  guardThatOwnerExists form.ownerId
  process <-
    newProcess
      form.ownerId
  withReadWritePool pool (Update.insertProcess process)
  pure ProcessRegistrationResult{processId = process.processId}

completeHandler :: ProcessId -> Eff RouteEffects NoContent
completeHandler processId = do
  Masna3Env{pool} <- Reader.ask
  guardThatProcessCompletable processId
  guardThatProcessFilesConfirmed processId
  withReadWritePool pool (Update.updateProcessStatus processId Completed)
  pure NoContent

cancelHandler :: ProcessId -> Eff RouteEffects NoContent
cancelHandler processId = do
  Masna3Env{pool} <- Reader.ask
  void $ guardThatLiveProcessExists processId
  withReadWritePool pool (Update.cancelProcess processId)
  pure NoContent
