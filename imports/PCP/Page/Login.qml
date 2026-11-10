import QtQuick 2.6

LoginForm {
    // FORK-ONLY: the button state is bound to the controller property.
    // The old code set "Logging in..." imperatively and reset it from
    // loginFailed/errorOccured signals; if one of those was missed the UI
    // stayed stuck on "Logging in..." forever. A binding cannot desync.
    loginButton.text: controller.loginInProgress ? "Logging in..." : "LOGIN"
    loginButton.enabled: !controller.loginInProgress

    Component.onCompleted: {
        serverField.accepted.connect(doLogin)
        usernameField.accepted.connect(doLogin)
        passwordField.accepted.connect(doLogin)
        // FORK-ONLY: the LOGIN button was never connected. LoginForm.ui.qml
        // declares the button and Login.qml binds its text and enabled state,
        // but nothing ever hooked a click to doLogin() - so pressing LOGIN did
        // nothing at all and only pressing Enter in a field worked.
        // (Verified in the harness: clicking the button's inner Button calls
        // nothing, while calling doLogin() directly does the login.)
        loginButton.clicked.connect(doLogin)
        controller.connectionAdded.connect(function(conn) {
            stackView.pop()
            accountListView.currentConnection = conn
        })
    }

    function doLogin() {
        loginError.visible = false
        // NOTE: Qt 5.6 V4 has no String.startsWith/includes — use indexOf.
        if (!(serverField.text.indexOf("http") === 0 && serverField.text.indexOf("://") !== -1)) {
            loginError.text = "Server address should start with http(s)://"
            loginError.visible = true
            return
        }
        if (!usernameField.text || !passwordField.text) {
            loginError.text = "Please fill in username and password"
            loginError.visible = true
            return
        }
        // Re-entrancy guard: the button binding also disables it, but
        // Enter could still fire while a login is in flight.
        if (controller.loginInProgress) return

        controller.loginWithCredentials(serverField.text, usernameField.text, passwordField.text)
    }
}