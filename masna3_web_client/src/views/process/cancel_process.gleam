import components/rsvp_error
import components/validation_error
import domain/process/cancel_process.{UserChangedProcessId, UserSubmittedForm}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import types/model.{type Model}
import types/msg.{type Msg, CancelProcessMsg}

pub fn view(model: Model) -> List(Element(Msg)) {
  [
    html.div([attribute.class("w-full flex items-center flex-col")], [
      html.h2([attribute.class("mb-4")], [html.text("Cancel Process")]),
      case list.is_empty(model.cancel_process.validation_errors) {
        True -> element.none()
        False -> validation_error.view(model.cancel_process.validation_errors)
      },
      case model.cancel_process.cancel_process_response {
        Some(Ok(s)) ->
          html.div(
            [
              attribute.class(
                "w-150 mb-2 p-3 border border-green-400 rounded-md bg-green-100",
              ),
            ],
            [
              html.h3([attribute.class("underline text-center")], [
                html.text("Process cancelled"),
              ]),
              html.p([], [html.text("Status: " <> int.to_string(s.status))]),
              html.p([], [html.text("Body: " <> s.body)]),
              html.p([], [html.text("Headers:")]),
              html.ul(
                [],
                s.headers
                  |> list.map(fn(pair) {
                    let #(header, value) = pair
                    html.li([], [html.text(header <> " : " <> value)])
                  }),
              ),
            ],
          )
        Some(Error(err)) -> rsvp_error.view(err, "Process not cancelled")
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
              html.text("Process ID"),
            ]),
            html.input([
              attribute.id("process_id"),
              attribute.class(
                "p-2 border border-neutral-300 rounded-md focus:outline-none focus:border-neutral-400 text-sm",
              ),
              event.on_input(fn(value) {
                CancelProcessMsg(UserChangedProcessId(value))
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
            [html.text("Cancel Process")],
          ),
        ],
      ),
    ]),
  ]
}

fn handle_submit(_) -> Msg {
  CancelProcessMsg(UserSubmittedForm)
}
