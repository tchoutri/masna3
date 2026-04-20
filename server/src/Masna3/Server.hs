module Masna3.Server where

import Auth.Biscuit.Servant
import Data.Aeson (encode)
import Data.Proxy
import Effectful
import Effectful.Error.Static
import Effectful.Log (Log, (.=))
import Effectful.Log qualified as Log
import Effectful.Reader.Static qualified as Reader
import Effectful.Time
import Log (Logger)
import Masna3.Api
import Masna3.Api.File
import Network.HTTP.Types.Method (methodDelete, methodGet, methodOptions, methodPost)
import Network.Wai.Handler.Warp
import Network.Wai.Log qualified as WaiLog
import Network.Wai.Middleware.Cors
import Servant qualified
import Servant.API (NamedRoutes)
import Servant.Server
import Servant.Server.Generic

import Masna3.Server.Effects
import Masna3.Server.Environment
import Masna3.Server.Error
import Masna3.Server.File

runMasna3
  :: IOE :> es
  => Logger
  -> Masna3Env
  -> Eff es ()
runMasna3 logger environment = do
  loggingMiddleware <- Log.runLog "masna3-server" logger Log.defaultLogLevel WaiLog.mkLogMiddleware
  let server = makeServer logger environment
  let warpSettings =
        setPort (fromIntegral environment.httpPort) defaultSettings
  liftIO
    $ runSettings warpSettings
    $ loggingMiddleware
      . const
    $ server

makeServer
  :: Logger
  -> Masna3Env
  -> Application
makeServer logger environment =
  cors (\_req -> Just corsPolicy) $
    serveWithContextT
      (Proxy @(NamedRoutes ServerRoutes))
      (genBiscuitCtx environment.publicKey)
      (handleRoute logger environment)
      masna3Server
  where
    corsPolicy =
      simpleCorsResourcePolicy
        { corsOrigins = Just (environment.allowedOrigins, True)
        , corsMethods = [methodGet, methodPost, methodDelete, methodOptions]
        , corsRequestHeaders = ["content-type"]
        , corsMaxAge = Just 3600
        }

handleRoute
  :: Logger
  -> Masna3Env
  -> Eff RouteEffects a
  -> Handler a
handleRoute logger env action = do
  err <-
    liftIO $
      Right
        <$> action
          & runErrorNoCallStackWith handleMasna3Error
          & Log.runLog "masna3-server" logger Log.defaultLogLevel
          & runTime
          & Reader.runReader env
          & runEff
  either Servant.throwError pure err

masna3Server :: ServerRoutes (AsServerT (Eff RouteEffects))
masna3Server =
  ServerRoutes
    { api = apiServer
    }

apiServer :: ServerT (NamedRoutes APIRoutes) (Eff RouteEffects)
apiServer =
  APIRoutes
    { files = fileServer
    }

fileServer :: ServerT (NamedRoutes FileRoutes) (Eff RouteEffects)
fileServer =
  FileRoutes
    { register = registerHandler
    , confirm = confirmHandler
    , cancel = cancelHandler
    , delete = deleteHandler
    }

handleMasna3Error :: Log :> es => Masna3Error -> Eff es (Either ServerError a)
handleMasna3Error masna3Error = do
  let servantError =
        let err = toServerError masna3Error
         in err{errBody = encode masna3Error}
  Log.logInfo "Server error" $
    Log.object
      [ "error_body" .= masna3Error
      , "error_code" .= errHTTPCode servantError
      ]
  pure $ Left servantError
