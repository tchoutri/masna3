module Masna3.Server.Owner.Guards where

import Data.Aeson
import Effectful
import Effectful.Error.Static (Error)
import Effectful.Error.Static qualified as Error
import Effectful.Log (Log)
import Effectful.Log qualified as Log
import Effectful.Reader.Static (Reader)
import Effectful.Reader.Static qualified as Reader
import Masna3.Api.Owner.OwnerId (OwnerId)

import Masna3.Database
import Masna3.Server.Environment (Masna3Env (..))
import Masna3.Server.Error
import Masna3.Server.Model.Owner.Query
import Masna3.Server.Model.Owner.Types

guardThatOwnerExists
  :: ( Error Masna3Error :> es
     , IOE :> es
     , Log :> es
     , Reader Masna3Env :> es
     )
  => OwnerId -> Eff es Owner
guardThatOwnerExists ownerId = do
  Masna3Env{pool} <- Reader.ask
  maybeOwner <- withReadOnlyPool pool (getOwnerById ownerId)
  case maybeOwner of
    Nothing ->
      Log.localData ["owner_id" .= ownerId] $
        Error.throwError (OwnerNotFoundError (OwnerNotFound ownerId))
    Just owner -> pure owner
