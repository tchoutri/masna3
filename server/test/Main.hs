module Main where

import Arbiter.Migrations qualified as Mig
import Control.Concurrent.MVar.Strict qualified as IOMVar
import Data.Proxy
import Data.Word
import Effectful
import Effectful.Concurrent.Async
import Effectful.Log qualified as Log
import Effectful.PostgreSQL
import Effectful.Reader.Static qualified as Reader
import Log.Backend.StandardOutput qualified as Log
import Network.Wai.Handler.Warp
import Network.Wai.Log qualified as WaiLog
import Test.Tasty

import Masna3.Server
import Masna3.Server.Environment
import Masna3.Server.Jobs.Types (AppRegistry)
import Masna3.Test.File qualified as File
import Masna3.Test.Process qualified as Process
import Masna3.Test.Utils

main :: IO ()
main = do
  testEnv' :: TestEnv <- runEff . runConcurrent $ getTestEnv
  semaphore <- IOMVar.newEmptyMVar'
  let testEnv = testEnv'{logSemaphore = semaphore}
  serverEnv <- runEff getMasna3Env
  Mig.runMigrationsForRegistry (Proxy @AppRegistry) serverEnv.connString "public" Mig.defaultMigrationConfig
  runEff . Reader.runReader testEnv $ withTestPool cleanUp
  let server = Log.withStdOutLogger $ \logger -> do
        loggingMiddleware <- Log.runLog "masna3-test-server" logger Log.defaultLogLevel WaiLog.mkLogMiddleware
        let warpSettings =
              defaultSettings
                & setPort (fromIntegral @Word16 @Int testEnv.httpPort)
                & setBeforeMainLoop (IOMVar.putMVar' semaphore ())
        liftIO
          $ runSettings warpSettings
          $ loggingMiddleware
            . const
          $ makeServer logger serverEnv
  runEff $ runConcurrent $ withAsync server $ \_ -> liftIO $ do
    IOMVar.readMVar' semaphore
    defaultMain $ testGroup "Masna3 Tests" (specs testEnv)

specs :: TestEnv -> [TestTree]
specs env =
  [ File.spec env
  , Process.spec env
  ]

cleanUp :: (IOE :> es, WithConnection :> es) => Eff es ()
cleanUp = do
  void $ execute_ "DELETE FROM processes"
  void $ execute_ "DELETE FROM files"
  void $ execute_ "DELETE FROM owners"
  void $ execute_ "DELETE FROM archived_processes"
  void $ execute_ "DELETE FROM archived_files"
