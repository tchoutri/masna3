module Masna3.Server.Model.Owner.Update where

import Database.PostgreSQL.Entity
import Effectful
import Effectful.Labeled
import Effectful.PostgreSQL

import Masna3.Database
import Masna3.Server.Model.Owner.Types

insertOwner
  :: ( IOE :> es
     , Labeled ReadWrite WithConnection :> es
     )
  => Owner -> Eff es ()
insertOwner owner = void $ labeled @ReadWrite @WithConnection $ execute (_insert @Owner) owner
