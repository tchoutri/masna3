module Masna3.Server.Process.Guards where

import Data.Aeson
import Effectful
import Effectful.Error.Static (Error)
import Effectful.Error.Static qualified as Error
import Effectful.Log (Log)
import Effectful.Log qualified as Log
import Effectful.Reader.Static (Reader)
import Effectful.Reader.Static qualified as Reader
import Masna3.Api.Process.ProcessId (ProcessId)

import Masna3.Database
import Masna3.Server.Environment (Masna3Env (..))
import Masna3.Server.Error
import Masna3.Server.Model.Process.Query
import Masna3.Server.Model.Process.Types

guardThatProcessExists :: (Error Masna3Error :> es, IOE :> es, Log :> es, Reader Masna3Env :> es) => ProcessId -> Eff es Process
guardThatProcessExists processId = do
  Masna3Env{pool} <- Reader.ask
  maybeProcess <- withReadOnlyPool pool (getProcessById processId)
  case maybeProcess of
    Nothing ->
      Log.localData ["process_id" .= processId] $
        Error.throwError (ProcessNotFoundError (ProcessNotFound processId))
    Just process -> pure process

guardThatLiveProcessExists :: (Error Masna3Error :> es, IOE :> es, Log :> es, Reader Masna3Env :> es) => ProcessId -> Eff es Process
guardThatLiveProcessExists processId = do
  Masna3Env{pool} <- Reader.ask
  maybeProcess <- withReadOnlyPool pool (getLiveProcessById processId)
  case maybeProcess of
    Nothing ->
      Log.localData ["process_id" .= processId] $
        Error.throwError (ProcessNotFoundError (ProcessNotFound processId))
    Just process -> pure process

guardThatProcessFilesConfirmed :: (Error Masna3Error :> es, IOE :> es, Log :> es, Reader Masna3Env :> es) => ProcessId -> Eff es ()
guardThatProcessFilesConfirmed processId = do
  Masna3Env{pool} <- Reader.ask
  unconfirmedFiles <- withReadOnlyPool pool (hasUnconfirmedFiles processId)
  case unconfirmedFiles of
    True ->
      Log.localData ["process_id" .= processId] $
        Error.throwError (ProcessFilesNotConfirmedError (ProcessFilesNotConfirmed processId))
    False -> pure ()

guardThatProcessCompletable :: (Error Masna3Error :> es, IOE :> es, Log :> es, Reader Masna3Env :> es) => ProcessId -> Eff es ()
guardThatProcessCompletable processId = do
  process <- guardThatProcessExists processId
  case process.status of
    Started ->
      Log.localData ["process_id" .= processId] $
        Error.throwError (InvalidTransition (NotStartedToCompleted (MkInvalidTransitionProcess processId)))
    Completed ->
      Log.localData ["file_id" .= processId] $
        Error.throwError (InvalidTransition (NotCompletedToCompleted (MkInvalidTransitionProcess processId)))
    InProgress -> pure ()

guardThatProcessCompleted :: (Error Masna3Error :> es, IOE :> es, Log :> es, Reader Masna3Env :> es) => ProcessId -> Eff es ()
guardThatProcessCompleted processId = do
  process <- guardThatProcessExists processId
  case process of
    Process{status = Completed} ->
      Log.localData ["process_id" .= process.processId] $
        Error.throwError (ProcessAlreadyCompletedError (ProcessAlreadyCompleted (process.processId)))
    _ -> pure ()
