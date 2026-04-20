import components/rsvp_error
import components/validation_error
import domain/process/register_process.{
  ProcessRegistrationResult, UserChangedOwnerId, UserSubmittedForm,
}
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import types/domain.{ProcessId}
import types/model.{type Model}
import types/msg.{type Msg, RegisterProcessMsg}

pub fn view(model: Model) -> List(Element(Msg)) {
  [
    html.div([attribute.class("w-full flex items-center flex-col")], [
      html.h2([attribute.class("mb-4")], [html.text("Register Process")]),
      case list.is_empty(model.register_process.validation_errors) {
        True -> element.none()
        False -> validation_error.view(model.register_process.validation_errors)
      },
      case model.register_process.register_process_response {
        Some(Ok(ProcessRegistrationResult(ProcessId(process_id)))) ->
          html.div(
            [
              attribute.class(
                "w-240 mb-2 p-3 border border-green-400 rounded-md bg-green-100",
              ),
            ],
            [
              html.h3([attribute.class("underline text-center")], [
                html.text("Process registered"),
              ]),
              html.p([], [html.text("Process ID: " <> process_id)]),
            ],
          )
        Some(Error(err)) -> rsvp_error.view(err, "Process not registered")
        None -> element.none()
      },
      html.form(
        [
          event.on_submit(handle_submit),
          attribute.class("flex flex-col gap-4 w-82"),
        ],
        [
          html.div([attribute.class("flex flex-col gap-1")], [
            html.label([attribute.class("text-sm text-neutral-600")], [
              html.text("Owner ID"),
            ]),
            html.input([
              attribute.id("owner_id"),
              attribute.class(
                "p-2 border border-neutral-300 rounded-md focus:outline-none focus:border-neutral-400 text-sm",
              ),
              event.on_input(fn(value) {
                RegisterProcessMsg(UserChangedOwnerId(value))
              }),
            ]),
          ]),
          html.button(
            [
              attribute.type_("submit"),
              attribute.class(
                "px-4 py-3 rounded-md border border-neutral-300 hover:border-neutral-400 hover:bg-neutral-100 text-sm font-medium text-neutral-800 cursor-pointer",
              ),
            ],
            [html.text("Register Process")],
          ),
        ],
      ),
    ]),
  ]
}

fn handle_submit(_) -> Msg {
  RegisterProcessMsg(UserSubmittedForm)
}
