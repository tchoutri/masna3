module Masna3.Api where

import GHC.Generics
import Servant.API

import Masna3.Api.File
import Masna3.Api.Process

data ServerRoutes mode = ServerRoutes
  { api :: mode :- "api" :> NamedRoutes APIRoutes
  }
  deriving (Generic)

data APIRoutes mode = APIRoutes
  { files :: mode :- "files" :> NamedRoutes FileRoutes
  , processes :: mode :- "processes" :> NamedRoutes ProcessRoutes
  }
  deriving (Generic)
