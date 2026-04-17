module Masna3.Server.Environment where

import Amazonka
import Amazonka.S3.Internal (BucketName)
import Auth.Biscuit (PublicKey)
import Data.ByteString (StrictByteString)
import Data.Pool (Pool)
import Data.Pool qualified as Pool
import Data.Time
import Data.Word
import Database.PostgreSQL.Simple qualified as PG
import Effectful
import Env qualified
import GHC.Generics (Generic)

import Masna3.Server.Config

data Masna3Env = Masna3Env
  { pool :: Pool PG.Connection
  , connString :: StrictByteString
  , dbConfig :: ConnectionPoolConfig
  , httpPort :: Word16
  , domain :: Text
  , mltp :: MLTP
  , deployed :: Bool
  , publicKey :: PublicKey
  , s3AuthEnv :: AuthEnv
  , awsRegion :: Region
  , awsBucket :: BucketName
  , allowedOrigins :: [StrictByteString]
  }
  deriving stock (Generic)

mkPool
  :: IOE :> es
  => StrictByteString -- Database access information
  -> NominalDiffTime -- Allowed timeout
  -> Int -- Number of connections
  -> Eff es (Pool PG.Connection)
mkPool connectionInfo timeout' connections =
  liftIO $
    Pool.newPool $
      Pool.defaultPoolConfig
        (PG.connectPostgreSQL connectionInfo)
        PG.close
        (realToFrac timeout')
        connections

configToEnv :: IOE :> es => Masna3Config -> Eff es Masna3Env
configToEnv masna3Config = do
  let ConnectionPoolConfig{connectionTimeout, connections} = masna3Config.dbConfig
  pool <- mkPool masna3Config.connectionInfo connectionTimeout connections
  let s3AuthEnv = AuthEnv masna3Config.awsKeyId masna3Config.awsSecret Nothing Nothing
  pure
    Masna3Env
      { pool = pool
      , dbConfig = masna3Config.dbConfig
      , connString = masna3Config.connectionInfo
      , httpPort = masna3Config.httpPort
      , domain = masna3Config.domain
      , mltp = masna3Config.mltp
      , deployed = masna3Config.deployed
      , publicKey = masna3Config.publicKey
      , s3AuthEnv
      , awsRegion = masna3Config.awsRegion
      , awsBucket = masna3Config.awsBucket
      , allowedOrigins = masna3Config.allowedOrigins
      }

getMasna3Env :: IOE :> es => Eff es Masna3Env
getMasna3Env = do
  config <- liftIO $ Env.parse identity parseConfig
  configToEnv config
