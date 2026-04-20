module Masna3.Server.Error where

import Data.Aeson
import Deriving.Aeson
import Masna3.Api.File.FileId
import Masna3.Api.Owner.OwnerId
import Masna3.Api.Process.ProcessId
import Servant (ServerError (..), err404, err409, err500)

newtype OwnerNotFound = OwnerNotFound {ownerId :: OwnerId}
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField] OwnerNotFound)

newtype ProcessNotFound = ProcessNotFound {processId :: ProcessId}
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField] ProcessNotFound)

newtype ProcessFilesNotConfirmed = ProcessFilesNotConfirmed {processId :: ProcessId}
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField] ProcessFilesNotConfirmed)

newtype ProcessAlreadyCompleted = ProcessAlreadyCompleted {processId :: ProcessId}
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField] ProcessAlreadyCompleted)

newtype FileNotFound = FileNotFound {fileId :: FileId}
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField] FileNotFound)

newtype MkInvalidTransitionFile = MkInvalidTransitionFile {fileId :: FileId}
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField] MkInvalidTransitionFile)

newtype MkInvalidTransitionProcess = MkInvalidTransitionProcess {processId :: ProcessId}
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField] MkInvalidTransitionProcess)

data Masna3Error
  = TooManyRows Text
  | OwnerNotFoundError OwnerNotFound
  | ProcessNotFoundError ProcessNotFound
  | ProcessFilesNotConfirmedError ProcessFilesNotConfirmed
  | ProcessAlreadyCompletedError ProcessAlreadyCompleted
  | FileNotFoundError FileNotFound
  | InvalidTransition InvalidTransitionError
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField] Masna3Error)

data InvalidTransitionError
  = NotPendingToUploaded MkInvalidTransitionFile
  | NotStartedToCompleted MkInvalidTransitionProcess
  | NotCompletedToCompleted MkInvalidTransitionProcess
  deriving stock (Eq, Generic, Ord, Show)
  deriving
    (FromJSON, ToJSON)
    via (CustomJSON '[FieldLabelModifier '[CamelToSnake], SumObjectWithSingleField] InvalidTransitionError)

toServerError :: Masna3Error -> ServerError
toServerError = \case
  TooManyRows _ -> err500
  OwnerNotFoundError _ -> err404
  ProcessNotFoundError _ -> err404
  ProcessFilesNotConfirmedError _ -> err409
  ProcessAlreadyCompletedError _ -> err409
  FileNotFoundError _ -> err404
  InvalidTransition _ -> err500
