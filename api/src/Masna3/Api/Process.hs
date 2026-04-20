module Masna3.Api.Process where

import Data.Aeson
import Deriving.Aeson
import Servant.API

import Masna3.Api.Owner.OwnerId
import Masna3.Api.Process.ProcessId

data ProcessRegistrationForm = ProcessRegistrationForm
  { ownerId :: OwnerId
  }
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField])
          ProcessRegistrationForm

data ProcessRegistrationResult = ProcessRegistrationResult
  { processId :: ProcessId
  }
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField])
          ProcessRegistrationResult

type RegisterProcess =
  Summary "Register a process for multi-file upload"
    :> "register"
    :> ReqBody '[JSON] ProcessRegistrationForm
    :> Post '[JSON] ProcessRegistrationResult

type CompleteProcess =
  Summary "Complete a multi-file upload process"
    :> Capture "process_id" ProcessId
    :> "complete"
    :> Post '[JSON] NoContent

type CancelProcess =
  Summary "Cancel a multi-file upload process"
    :> Capture "process_id" ProcessId
    :> "cancel"
    :> Post '[JSON] NoContent

data ProcessRoutes mode = ProcessRoutes
  { register :: mode :- RegisterProcess
  , complete :: mode :- CompleteProcess
  , cancel :: mode :- CancelProcess
  }
  deriving stock (Generic)
