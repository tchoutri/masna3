module Masna3.Server.Owner.Guards where

import Data.Aeson
import Effectful
import Effectful.Error.Static qualified as Error
import Effectful.Log qualified as Log
import Masna3.Api.Owner.OwnerId (OwnerId)

import Masna3.Server.Database
import Masna3.Server.Effects
import Masna3.Server.Error
import Masna3.Server.Model.Owner.Query
import Masna3.Server.Model.Owner.Types

guardThatOwnerExists :: OwnerId -> Eff RouteEffects Owner
guardThatOwnerExists ownerId = do
  maybeOwner <- withPool (getOwnerById ownerId)
  case maybeOwner of
    Nothing ->
      Log.localData ["owner_id" .= ownerId] $
        Error.throwError (OwnerNotFoundError (OwnerNotFound ownerId))
    Just owner -> pure owner
