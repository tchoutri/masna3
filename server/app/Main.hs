module Main where

import Arbiter.Servant qualified as ArbServant
import Arbiter.Servant.UI qualified as ArbUI
import Arbiter.Simple
import Arbiter.Simple qualified as ArbS
import Arbiter.Worker (WorkerConfig)
import Arbiter.Worker qualified as Worker
import Data.Proxy
import Data.Time
import Effectful
import Effectful.Concurrent
import Effectful.Concurrent.Async
import Effectful.Console.ByteString
import Effectful.Console.ByteString qualified as Console
import Effectful.Dispatch.Static
import Effectful.Log (Log)
import Effectful.Log qualified as Log
import Effectful.Reader.Static
import Effectful.Time
import Effectful.Time qualified as Time
import Log.Backend.StandardOutput qualified as Log
import Network.Wai.Handler.Warp

import Masna3.Server (runMasna3)
import Masna3.Server.Environment
import Masna3.Server.Jobs.Types

main :: IO ()
main = runEff . runConsole . runTime . runConcurrent $ do
  env <- getMasna3Env
  arbiterEnv <- ArbS.createSimpleEnv (Proxy @AppRegistry) env.connString "public"
  arbiterUiEnv <- liftIO $ ArbServant.initArbiterServer (Proxy @AppRegistry) env.connString "public"
  let warpSettings =
        setPort 8086 defaultSettings
  void $
    forkIO $ do
      Console.putStrLn "Admin UI at http://localhost:8086"
      unsafeEff_ $
        runSettings warpSettings $
          ArbUI.arbiterAppWithAdmin @AppRegistry arbiterUiEnv
  runReader env $
    Log.withStdOutLogger $ \jobsLogger -> do
      Log.runLog "masna3-jobs" jobsLogger Log.defaultLogLevel $
        runTime $ do
          arbiterWorkerConfig <- Worker.defaultWorkerConfig env.connString 5 (processArbiterJob jobsLogger)
          preflightChecks arbiterEnv
          withAsync (startJobs arbiterEnv arbiterWorkerConfig) $ \_ ->
            Log.withStdOutLogger $ \serverLogger -> do
              runMasna3 serverLogger env

preflightChecks
  :: ( IOE :> es
     , Time :> es
     )
  => (ArbS.SimpleEnv AppRegistry)
  -> Eff es ()
preflightChecks arbiterEnv = do
  now <- Time.currentTime
  let oneDayLater = (24 * 60 * 60) `addUTCTime` now
  void $ insertDelayedJob arbiterEnv oneDayLater PurgeExpiredFiles

startJobs
  :: IOE :> es
  => SimpleEnv AppRegistry
  -> WorkerConfig (SimpleDb AppRegistry IO) Masna3Job ()
  -> Eff es ()
startJobs arbiterEnv arbiterWorkerConfig = liftIO $ ArbS.runSimpleDb arbiterEnv $ Worker.runWorkerPool arbiterWorkerConfig
