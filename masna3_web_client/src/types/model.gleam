import domain/file/confirm_file.{type Model as ConfirmFileModel}
import domain/file/delete_file.{type Model as DeleteFileModel}
import domain/file/register_file.{type Model as RegisterFileModel}
import domain/process/cancel_process.{type Model as CancelProcessModel}
import domain/process/complete_process.{type Model as CompleteProcesssModel}
import domain/process/register_process.{type Model as RegisterProcessModel}
import types/route.{type Route}

pub type Model {
  Model(
    route: Route,
    register_file: RegisterFileModel,
    confirm_file: ConfirmFileModel,
    delete_file: DeleteFileModel,
    register_process: RegisterProcessModel,
    complete_process: CompleteProcesssModel,
    cancel_process: CancelProcessModel,
  )
}
