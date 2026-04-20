import gleam/uri

import lustre/attribute.{type Attribute}

pub type Route {
  Index
  RegisterFile
  ConfirmFile
  DeleteFile
  RegisterProcess
  CompleteProcess
  CancelProcess
  NotFound(uri: uri.Uri)
}

/// Utility function for type-safe routing.
/// Assuming this function is kept in sync
/// with `parse_route` from `router.gleam`
pub fn href(route: Route) -> Attribute(msg) {
  let url = case route {
    Index -> "/"
    RegisterFile -> "/file/register"
    ConfirmFile -> "/file/confirm"
    DeleteFile -> "/file/delete"
    RegisterProcess -> "/process/register"
    CompleteProcess -> "/process/complete"
    CancelProcess -> "/process/cancel"
    NotFound(_) -> "/404"
  }

  attribute.href(url)
}
