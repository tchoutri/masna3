{-# LANGUAGE TypeData #-}

module Masna3.Database
  ( AccessMode (..)
  , withReadWritePool
  , withReadOnlyPool
  ) where

import Data.Pool (Pool)
import Database.PostgreSQL.Simple qualified as PG
import Effectful
import Effectful.Labeled
import Effectful.PostgreSQL (WithConnection)
import Effectful.PostgreSQL qualified as DB

type data AccessMode
  = ReadOnly
  | ReadWrite

withPool
  :: forall a es
   . IOE :> es
  => Pool PG.Connection
  -> Eff (WithConnection ': es) a
  -> Eff es a
withPool pool action = do
  DB.runWithConnectionPool pool $
    DB.withTransaction action

withReadWritePool
  :: forall a es
   . IOE :> es
  => (Pool PG.Connection)
  -> Eff (Labeled ReadWrite WithConnection ': es) a
  -> Eff es a
withReadWritePool pool action = runLabeled (withPool pool) action

withReadOnlyPool
  :: forall a es
   . IOE :> es
  => (Pool PG.Connection)
  -> Eff (Labeled ReadOnly WithConnection ': es) a
  -> Eff es a
withReadOnlyPool pool action = runLabeled (withPool pool) action
