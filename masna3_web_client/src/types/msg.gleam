import domain/file/confirm_file.{type Msg as ConfirmFileMsg}
import domain/file/delete_file.{type Msg as DeleteFileMsg}
import domain/file/register_file.{type Msg as RegisterFileMsg}
import domain/process/cancel_process.{type Msg as CancelProcessMsg}
import domain/process/complete_process.{type Msg as CompleteProcessMsg}
import domain/process/register_process.{type Msg as RegisterProcessMsg}
import types/route.{type Route}

pub type Msg {
  UserNavigatedTo(route: Route)
  RegisterFileMsg(RegisterFileMsg)
  ConfirmFileMsg(ConfirmFileMsg)
  DeleteFileMsg(DeleteFileMsg)
  RegisterProcessMsg(RegisterProcessMsg)
  CompleteProcessMsg(CompleteProcessMsg)
  CancelProcessMsg(CancelProcessMsg)
}
