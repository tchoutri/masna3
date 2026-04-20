module BackgroundJobs.FileJob where

import Data.Aeson
import Database.PostgreSQL.Simple.FromField
import Database.PostgreSQL.Simple.Newtypes
import Database.PostgreSQL.Simple.ToField
import Deriving.Aeson

data FileJob
  = PrintMessage Text
  | PurgeOrphanFiles
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField])
          FileJob
  deriving
    (FromField, ToField)
    via Aeson FileJob
