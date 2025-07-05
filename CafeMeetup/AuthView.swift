import SwiftUI
import Supabase

struct AuthView: View {
    @State private var isSignup = false
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(isSignup ? "Sign Up" : "Log In")
                .font(.largeTitle)
                .bold()

            if isSignup {
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                isSignup ? signUp() : logIn()
            }) {
                Text(isSignup ? "Create Account" : "Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: {
                isSignup.toggle()
            }) {
                Text(isSignup ? "Already have an account? Log In" : "No account? Sign Up")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }

    func signUp() {
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("users")
                    .insert([
                        "first_name": firstName,
                        "last_name": lastName,
                        "email": email,
                        "password": password
                    ])
                // Navigate to homepage (next step)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func logIn() {
        Task {
            do {
                let result = try await SupabaseManager.shared.client
                    .from("users")
                    .select()
                    .eq("email", email)
                    .eq("password", password)
                    .single()
                    .execute()

                if result.error == nil {
                    // Navigate to homepage (next step)
                } else {
                    errorMessage = "Invalid login credentials"
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
