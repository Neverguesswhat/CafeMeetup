import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var firstName = ""
    @State private var userStatus = "default"

    var body: some View {
        if isLoggedIn {
            MainTabView(
                isLoggedIn: $isLoggedIn,
                firstName: $firstName,
                userStatus: $userStatus
            )
        } else {
            AuthView(
                isLoggedIn: $isLoggedIn,
                firstName: $firstName,
                userStatus: $userStatus
            )
        }
    }
}
