import Xee

private func trackOnboarding() {
    // snippet: track-basic
    Xee.track("onboarding_started")
    Xee.track("onboarding_step_viewed", properties: ["screen": "goals", "step": 2])
    Xee.track("onboarding_notifications_allowed", properties: ["granted": true])
    // end snippet
}

private func timeOnboarding() {
    // snippet: track-time
    Xee.time("onboarding_finished")   // when the first screen appears
    // ... the user goes through the screens ...
    Xee.track("onboarding_finished")  // carries duration_ms, the milliseconds since time()
    // end snippet
}
