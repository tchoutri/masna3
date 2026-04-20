import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}

import lustre/effect.{type Effect}
import rsvp

import config
import types/domain.{type OwnerId, type ProcessId, OwnerId, ProcessId}
import validation.{type ValidationError}

pub type Msg {
  UserChangedOwnerId(String)
  UserSubmittedForm
  ApiReturnedRegisteredProcess(Result(ProcessRegistrationResult, rsvp.Error))
}

pub type Model {
  Model(
    register_process_form: ProcessRegistrationForm,
    validation_errors: List(ValidationError),
    register_process_response: Option(
      Result(ProcessRegistrationResult, rsvp.Error),
    ),
  )
}

pub type ProcessRegistrationForm {
  ProcessRegistrationForm(owner_id: OwnerId)
}

pub type ProcessRegistrationResult {
  ProcessRegistrationResult(process_id: ProcessId)
}

pub fn send(form: ProcessRegistrationForm) -> Effect(Msg) {
  let decoder = {
    use process_id <- decode.field("process_id", decode.string)
    decode.success(ProcessRegistrationResult(process_id: ProcessId(process_id)))
  }

  let OwnerId(owner_id_string) = form.owner_id

  let body =
    json.object([
      #("owner_id", json.string(owner_id_string)),
    ])

  let url = config.api_base_url <> "/processes/register"
  let handler = rsvp.expect_json(decoder, ApiReturnedRegisteredProcess)

  rsvp.post(url, body, handler)
}

pub fn init() -> Model {
  let register_process_form = ProcessRegistrationForm(owner_id: OwnerId(""))

  Model(
    register_process_form:,
    register_process_response: None,
    validation_errors: [],
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserChangedOwnerId(v) -> {
      let form = ProcessRegistrationForm(owner_id: OwnerId(v))

      #(Model(..model, register_process_form: form), effect.none())
    }
    UserSubmittedForm -> {
      let validation_errors = validate(model.register_process_form)
      let new_model =
        Model(..model, validation_errors:, register_process_response: None)
      case validation_errors {
        [] -> #(new_model, send(new_model.register_process_form))
        _ -> #(new_model, effect.none())
      }
    }
    ApiReturnedRegisteredProcess(Ok(registered_process)) -> #(
      Model(..model, register_process_response: Some(Ok(registered_process))),
      effect.none(),
    )
    ApiReturnedRegisteredProcess(Error(err)) -> #(
      Model(..model, register_process_response: Some(Error(err))),
      effect.none(),
    )
  }
}

fn validate(form: ProcessRegistrationForm) -> List(ValidationError) {
  let OwnerId(owner_id_string) = form.owner_id

  [
    validation.validate_uuid(owner_id_string),
  ]
  |> option.values()
}
