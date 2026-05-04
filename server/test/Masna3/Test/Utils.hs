module Masna3.Test.Utils
  ( TestEff
  , TestEnv (..)
  , testThis
  , assertEqual
  , assertFailure
  , assertBool
  , assertJust
  , assertNothing
  , assertRight
  , assertLeft
  , assertLeftWithStatus
  , runRequest
  , getTestEnv
  ) where

import Data.Text qualified as Text
import Data.Text.IO qualified as Text
import Data.Word
import Effectful
import Effectful.Concurrent.MVar.Strict (Concurrent)
import Effectful.Concurrent.MVar.Strict qualified as MVar
import Effectful.Error.Static (Error)
import Effectful.Error.Static qualified as Error
import Effectful.Exception
import Effectful.Labeled
import Effectful.Log (Log)
import Effectful.Log qualified as Log
import Effectful.PostgreSQL (WithConnection)
import Effectful.PostgreSQL qualified as DB
import Effectful.Reader.Static (Reader)
import Effectful.Reader.Static qualified as Reader
import Effectful.Time (Time)
import Effectful.Time qualified as Time
import Env qualified
import GHC.Stack
import Log.Backend.LogList qualified as Log
import Network.HTTP.Client (defaultManagerSettings, newManager)
import Network.HTTP.Types (statusCode)
import Servant.Client
import Test.Tasty (TestTree)
import Test.Tasty.HUnit qualified as Test

import Masna3.Database
import Masna3.Server.Config
import Masna3.Server.Environment
import Masna3.Server.Error

type TestEff a =
  Eff
    '[ Time
     , Error Masna3Error
     , Reader TestEnv
     , Log
     , Concurrent
     , IOE
     ]
    a

testThis :: TestEnv -> Text -> TestEff () -> TestTree
testThis env name assertion = Test.testCase (Text.unpack name) $ do
  runEff . MVar.runConcurrent $ do
    logList <- Log.newLogList
    let displayLogsOnException :: (Concurrent :> es, IOE :> es) => Eff es ()
        displayLogsOnException = do
          MVar.withMVar' env.logSemaphore $ \() -> liftIO $ do
            Text.putStrLn $ "Logs from tests: " <> name <> ":"
            logs <- Log.getLogList logList
            forM_ logs (Text.putStrLn . Log.showLogMessage Nothing)
    do
      -- bracket_ insertList deleteList $ do
      Log.withLogListLogger logList $ \logger -> do
        assertion
          & Time.runTime
          & Error.runErrorWith handleTestSuiteError
          & Reader.runReader env
          & Log.runLog "masna3-test" logger Log.defaultLogLevel
          & (`onException` displayLogsOnException)
  where
    handleTestSuiteError :: IOE :> es => CallStack -> Masna3Error -> Eff es a
    handleTestSuiteError callstack err = do
      liftIO $ putStrLn $ prettyCallStack callstack
      error (show err)

assertEqual :: (Eq a, HasCallStack, Show a) => String -> a -> a -> TestEff ()
assertEqual message expected actual = liftIO $ Test.assertEqual message expected actual

assertBool :: HasCallStack => String -> Bool -> TestEff ()
assertBool message assertion = liftIO $ Test.assertBool message assertion

assertFailure :: HasCallStack => String -> TestEff ()
assertFailure = liftIO . Test.assertFailure

assertJust :: HasCallStack => String -> Maybe a -> TestEff a
assertJust _ (Just a) = pure a
assertJust message Nothing = liftIO $ Test.assertFailure message

assertNothing :: HasCallStack => String -> Maybe a -> TestEff ()
assertNothing message (Just _) = liftIO $ Test.assertFailure message
assertNothing _ Nothing = pure ()

assertRight :: HasCallStack => String -> Either a b -> TestEff b
assertRight _ (Right b) = pure b
assertRight message (Left _a) = liftIO $ Test.assertFailure message

assertLeft :: HasCallStack => String -> Either a b -> TestEff a
assertLeft description (Right _b) = liftIO $ Test.assertFailure description
assertLeft _ (Left a) = pure a

assertLeftWithStatus :: HasCallStack => String -> Int -> Either ClientError a -> TestEff ()
assertLeftWithStatus description expectedCode requestResult = do
  clientError <- assertLeft description requestResult
  case clientError of
    FailureResponse _ resp -> compareStatusCodes resp
    InvalidContentTypeHeader resp -> compareStatusCodes resp
    DecodeFailure _ resp -> compareStatusCodes resp
    UnsupportedContentType _ resp -> compareStatusCodes resp
    ConnectionError _ -> liftIO $ Test.assertFailure $ description <> ". Expected status " <> show expectedCode <> ". Connection error."
  where
    compareStatusCodes :: Response -> TestEff ()
    compareStatusCodes response
      | statusCode (responseStatusCode response) == expectedCode = pure ()
      | otherwise =
          liftIO $
            Test.assertFailure $
              description
                <> ". Expected status "
                <> show expectedCode
                <> " but received "
                <> show ((response.responseStatusCode).statusCode)

runRequest :: ClientM a -> TestEff (Either ClientError a)
runRequest request = do
  env <- Reader.ask @TestEnv
  manager <- liftIO $ newManager defaultManagerSettings
  url <- parseBaseUrl "localhost"
  let clientEnv = mkClientEnv manager $ url{baseUrlPort = fromIntegral @Word16 @Int env.httpPort}
  liftIO $ runClientM request clientEnv

getTestEnv :: (Concurrent :> es, IOE :> es) => Eff es TestEnv
getTestEnv = do
  config <- liftIO $ Env.parse identity parseTestConfig
  testConfigToEnv config
  where
    testConfigToEnv :: (Concurrent :> es, IOE :> es) => TestConfig -> Eff es TestEnv
    testConfigToEnv config = do
      let ConnectionPoolConfig{connectionTimeout, connections} = config.dbConfig
      pool <- mkPool config.connectionInfo connectionTimeout connections
      logSemaphore <- MVar.newEmptyMVar'
      pure
        TestEnv
          { pool = pool
          , httpPort = config.httpPort
          , logSemaphore = logSemaphore
          , connString = config.connectionInfo
          }
