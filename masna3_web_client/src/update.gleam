import lustre/effect.{type Effect}

import domain/file/confirm_file
import domain/file/delete_file
import domain/file/register_file
import domain/process/cancel_process
import domain/process/complete_process
import domain/process/register_process
import types/model.{type Model, Model}
import types/msg.{
  type Msg, CancelProcessMsg, CompleteProcessMsg, ConfirmFileMsg, DeleteFileMsg,
  RegisterFileMsg, RegisterProcessMsg, UserNavigatedTo,
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigatedTo(route:) -> {
      #(Model(..model, route:), effect.none())
    }

    RegisterFileMsg(register_msg) -> {
      let #(new_register_file_model, register_file_effect) =
        register_file.update(model.register_file, register_msg)

      #(
        Model(..model, register_file: new_register_file_model),
        effect.map(register_file_effect, RegisterFileMsg),
      )
    }

    ConfirmFileMsg(confirm_msg) -> {
      let #(new_confirm_file_model, confirm_file_effect) =
        confirm_file.update(model.confirm_file, confirm_msg)

      #(
        Model(..model, confirm_file: new_confirm_file_model),
        effect.map(confirm_file_effect, ConfirmFileMsg),
      )
    }

    DeleteFileMsg(delete_msg) -> {
      let #(new_delete_file_model, delete_file_effect) =
        delete_file.update(model.delete_file, delete_msg)

      #(
        Model(..model, delete_file: new_delete_file_model),
        effect.map(delete_file_effect, DeleteFileMsg),
      )
    }

    RegisterProcessMsg(register_msg) -> {
      let #(new_register_process_model, register_process_effect) =
        register_process.update(model.register_process, register_msg)

      #(
        Model(..model, register_process: new_register_process_model),
        effect.map(register_process_effect, RegisterProcessMsg),
      )
    }

    CompleteProcessMsg(complete_msg) -> {
      let #(new_complete_process_model, complete_process_effect) =
        complete_process.update(model.complete_process, complete_msg)

      #(
        Model(..model, complete_process: new_complete_process_model),
        effect.map(complete_process_effect, CompleteProcessMsg),
      )
    }

    CancelProcessMsg(cancel_msg) -> {
      let #(new_cancel_process_model, cancel_process_effect) =
        cancel_process.update(model.cancel_process, cancel_msg)

      #(
        Model(..model, cancel_process: new_cancel_process_model),
        effect.map(cancel_process_effect, CancelProcessMsg),
      )
    }
  }
}
