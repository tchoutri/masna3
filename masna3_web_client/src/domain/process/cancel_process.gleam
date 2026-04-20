import gleam/http/response
import gleam/json
import gleam/option.{type Option, None, Some}

import lustre/effect.{type Effect}
import rsvp

import config
import types/domain.{type ProcessId, ProcessId}
import validation.{type ValidationError}

pub type Msg {
  UserChangedProcessId(String)
  UserSubmittedForm
  ApiReturnedCancelledProcess(Result(response.Response(String), rsvp.Error))
}

pub type Model {
  Model(
    process_id: ProcessId,
    validation_errors: List(ValidationError),
    cancel_process_response: Option(
      Result(response.Response(String), rsvp.Error),
    ),
  )
}

pub fn send(process_id: ProcessId) -> Effect(Msg) {
  let ProcessId(id) = process_id
  let url = config.api_base_url <> "/processes/" <> id <> "/cancel"
  let handler = rsvp.expect_ok_response(ApiReturnedCancelledProcess)

  rsvp.post(url, json.object([]), handler)
}

pub fn init() -> Model {
  let process_id = ProcessId("")

  Model(process_id:, cancel_process_response: None, validation_errors: [])
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserChangedProcessId(v) -> {
      let process_id = ProcessId(v)

      #(Model(..model, process_id:), effect.none())
    }
    UserSubmittedForm -> {
      let validation_errors = validate(model.process_id)
      let new_model =
        Model(..model, validation_errors:, cancel_process_response: None)
      case validation_errors {
        [] -> #(new_model, send(new_model.process_id))
        _ -> #(new_model, effect.none())
      }
    }
    ApiReturnedCancelledProcess(Ok(cancelled_process)) -> #(
      Model(..model, cancel_process_response: Some(Ok(cancelled_process))),
      effect.none(),
    )
    ApiReturnedCancelledProcess(Error(err)) -> #(
      Model(..model, cancel_process_response: Some(Error(err))),
      effect.none(),
    )
  }
}

fn validate(process_id: ProcessId) -> List(ValidationError) {
  let ProcessId(process_id_string) = process_id

  [validation.validate_uuid(process_id_string)]
  |> option.values()
}
