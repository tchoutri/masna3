{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE QuasiQuotes #-}

module Masna3.Server.Model.Owner.Query where

import Database.PostgreSQL.Entity
import Database.PostgreSQL.Entity.Internal.QQ
import Database.PostgreSQL.Simple.Types
import Effectful
import Effectful.Error.Static (Error)
import Effectful.Error.Static qualified as Error
import Effectful.Labeled
import Effectful.PostgreSQL
import Masna3.Api.Owner.OwnerId

import Masna3.Database
import Masna3.Server.Error
import Masna3.Server.Model.Owner.Types

getOwnerById
  :: ( Error Masna3Error :> es
     , IOE :> es
     , Labeled ReadOnly WithConnection :> es
     )
  => OwnerId -> Eff es (Maybe Owner)
getOwnerById ownerId = labeled @ReadOnly @WithConnection $ do
  result <- query (_select @Owner <> _where [[field| owner_id |]]) (Only ownerId)
  case result of
    [] -> pure Nothing
    [r] -> pure (Just r)
    _ -> Error.throwError (TooManyRows (display ownerId))
