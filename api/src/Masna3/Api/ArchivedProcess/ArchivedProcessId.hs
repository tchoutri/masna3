module Masna3.Api.ArchivedProcess.ArchivedProcessId where

import Control.Monad.IO.Class
import Data.Aeson
import Data.Text.Display
import Data.UUID.Types
import Database.PostgreSQL.Simple.FromField
import Database.PostgreSQL.Simple.ToField
import GHC.Generics
import Heptapod qualified
import Servant.API

newtype ArchivedProcessId = ArchivedProcessId UUID
  deriving stock (Generic)
  deriving
    (Display)
    via ShowInstance UUID
  deriving
    (Eq, FromField, FromHttpApiData, FromJSON, Ord, Show, ToField, ToHttpApiData, ToJSON)
    via UUID

newArchivedProcessId :: MonadIO m => m ArchivedProcessId
newArchivedProcessId = ArchivedProcessId <$> Heptapod.generate
