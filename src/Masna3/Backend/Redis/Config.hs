module Masna3.Backend.Redis.Config where

import Data.ByteString
import Database.Redis

data RedisBackendConfig = RedisBackendConfig
  { jobsKeyspace :: StrictByteString
  , consumersKeyspace :: StrictByteString
  , maxSimultaneousJobs :: Word
  }
