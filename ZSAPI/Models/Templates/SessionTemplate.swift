extension Session {
  internal static let template = Session(
    id: PaypalLoginAuthResponse.template.session,
    user: PaypalLoginAuthResponse.template.userId
  )
}

extension PaypalLoginAuthResponse {
  internal static let template = PaypalLoginAuthResponse(userId: "user-deadbeef", session: "session-deadbeef")
}
