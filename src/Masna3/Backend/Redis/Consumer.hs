module Masna3.Backend.Redis.Consumer where

import Data.UUID.Types (UUID)
import Database.Redis

import Masna3.Backend.Redis.Config

data RedisConsumer = RedisConsumer
  { consumerId :: UUID
  }

registerConsumer :: MonadRedis m => RedisBackendConfig -> m ()
registerConsumer config = undefined
