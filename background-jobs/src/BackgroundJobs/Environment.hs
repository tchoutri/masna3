module BackgroundJobs.Environment
  ( BackgroundJobsConfig (..)
  , getBackgroundJobsEnv
  ) where

import Data.ByteString (StrictByteString)
import Effectful
import Env
import GHC.Generics

data BackgroundJobsConfig = BackgroundJobsConfig
  { connectionString :: StrictByteString
  }
  deriving stock (Generic)

parseConnectionInfo :: Parser Error StrictByteString
parseConnectionInfo =
  var str "JOBS_DB_CONNSTRING" (help "libpq-compatible connection string")

parseConfig :: Parser Error BackgroundJobsConfig
parseConfig =
  BackgroundJobsConfig
    <$> parseConnectionInfo

getBackgroundJobsEnv :: IOE :> es => Eff es BackgroundJobsConfig
getBackgroundJobsEnv = liftIO $ Env.parse identity parseConfig
