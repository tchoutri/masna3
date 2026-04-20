import gleam/http/response
import gleam/json
import gleam/option.{type Option, None, Some}

import lustre/effect.{type Effect}
import rsvp

import config
import types/domain.{type FileId, FileId}
import validation.{type ValidationError}

pub type Msg {
  UserChangedFileId(String)
  UserSubmittedForm
  ApiReturnedConfirmedFile(Result(response.Response(String), rsvp.Error))
}

pub type Model {
  Model(
    file_id: FileId,
    validation_errors: List(ValidationError),
    confirm_file_response: Option(Result(response.Response(String), rsvp.Error)),
  )
}

pub fn send(file_id: FileId) -> Effect(Msg) {
  let FileId(id) = file_id
  let url = config.api_base_url <> "/files/" <> id <> "/confirm"
  let handler = rsvp.expect_ok_response(ApiReturnedConfirmedFile)

  rsvp.post(url, json.object([]), handler)
}

pub fn init() -> Model {
  let file_id = FileId("")

  Model(file_id:, confirm_file_response: None, validation_errors: [])
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserChangedFileId(v) -> {
      let file_id = FileId(v)

      #(Model(..model, file_id:), effect.none())
    }
    UserSubmittedForm -> {
      let validation_errors = validate(model.file_id)
      let new_model =
        Model(..model, validation_errors:, confirm_file_response: None)
      case validation_errors {
        [] -> #(new_model, send(new_model.file_id))
        _ -> #(new_model, effect.none())
      }
    }
    ApiReturnedConfirmedFile(Ok(confirmed_file)) -> #(
      Model(..model, confirm_file_response: Some(Ok(confirmed_file))),
      effect.none(),
    )
    ApiReturnedConfirmedFile(Error(err)) -> #(
      Model(..model, confirm_file_response: Some(Error(err))),
      effect.none(),
    )
  }
}

fn validate(file_id: FileId) -> List(ValidationError) {
  let FileId(file_id_string) = file_id

  [validation.validate_uuid(file_id_string)]
  |> option.values()
}
