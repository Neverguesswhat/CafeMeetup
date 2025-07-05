import SwiftUI
import Supabase

struct AuthView: View {
    @Binding var isLoggedIn: Bool
    @Binding var firstName: String
    @Binding var userStatus: String

    @State private var isSignup = false
    @State private var inputFirstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showAccountExistsMessage = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(isSignup ? "Create Account" : "Log In")
                .font(.title)
                .bold()

            if isSignup {
                TextField("First Name", text: $inputFirstName)
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .textContentType(.givenName)

                TextField("Last Name", text: $lastName)
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .textContentType(.familyName)
            }

            TextField("Email", text: $email)
                .padding(12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)

            SecureField("Password", text: $password)
                .padding(12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .textContentType(isSignup ? .newPassword : .password)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                handleAuthAction()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isSignup ? "Create Account" : "Log In")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoading ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading)

            Button(action: {
                withAnimation {
                    isSignup.toggle()
                    clearForm()
                }
            }) {
                HStack(spacing: 4) {
                    Text(isSignup ? "Already have an account?" : "No account yet?")
                        .foregroundColor(.primary)
                    Text(isSignup ? "Log In" : "Create Account")
                        .foregroundColor(.blue)
                }
                .font(.body)
            }
            .disabled(isLoading)

            if showAccountExistsMessage {
                Text("You already have an account. Please log in.")
                    .foregroundColor(.orange)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }

    private func handleAuthAction() {
        clearMessages()
        
        if isSignup {
            guard validateSignupFields() else { return }
            signUp()
        } else {
            guard validateLoginFields() else { return }
            logIn()
        }
    }

    private func validateSignupFields() -> Bool {
        if inputFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
           lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
           email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
           password.isEmpty {
            errorMessage = "All fields are required."
            return false
        }
        
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address."
            return false
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters long."
            return false
        }
        
        return true
    }

    private func validateLoginFields() -> Bool {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty {
            errorMessage = "Email and password are required."
            return false
        }
        
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address."
            return false
        }
        
        return true
    }

    private func clearMessages() {
        errorMessage = ""
        showAccountExistsMessage = false
    }

    private func clearForm() {
        inputFirstName = ""
        lastName = ""
        email = ""
        password = ""
        clearMessages()
    }

    func signUp() {
        isLoading = true
        
        Task {
            do {
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let trimmedFirstName = inputFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let authResponse = try await SupabaseManager.shared.client.auth.signUp(
                    email: trimmedEmail,
                    password: password
                )

                let userId = authResponse.user.id
                let _ = try await SupabaseManager.shared.client
                    .from("users")
                    .insert([
                        "id": userId,
                        "email": trimmedEmail,
                        "first_name": trimmedFirstName,
                        "last_name": trimmedLastName,
                        "status": "default",
                        "photo_url": nil,
                        "location": nil,
                        "bio": nil
                    ])
                    .execute()

                await MainActor.run {
                    firstName = trimmedFirstName
                    userStatus = "default"
                    isLoggedIn = true
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    handleSignupError(error)
                }
            }
        }
    }

    private func handleSignupError(_ error: Error) {
        let errorDescription = error.localizedDescription
        
        if errorDescription.contains("duplicate key") || errorDescription.contains("User already registered") {
            isSignup = false
            showAccountExistsMessage = true
        } else if errorDescription.contains("Password should be at least 6 characters") {
            errorMessage = "Password must be at least 6 characters long."
        } else if errorDescription.contains("Invalid email") {
            errorMessage = "Please enter a valid email address."
        } else {
            errorMessage = "Sign up failed: \(errorDescription)"
        }
    }

    func logIn() {
        isLoading = true
        
        Task {
            do {
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                try await SupabaseManager.shared.client.auth.signIn(
                    email: trimmedEmail,
                    password: password
                )

                let response = try await SupabaseManager.shared.client
                    .from("users")
                    .select("first_name, status")
                    .eq("email", value: trimmedEmail)
                    .single()
                    .execute()

                let data = response.data
                struct LoginUser: Decodable {
                    let first_name: String
                    let status: String
                }
                if let loginUser = try? JSONDecoder().decode(LoginUser.self, from: data) {
                    await MainActor.run {
                        firstName = loginUser.first_name
                        userStatus = loginUser.status
                        isLoggedIn = true
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Could not retrieve user data. Please try again."
                    }
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    handleLoginError(error)
                }
            }
        }
    }

    private func handleLoginError(_ error: Error) {
        let errorDescription = error.localizedDescription
        
        if errorDescription.contains("Invalid login credentials") {
            errorMessage = "Invalid email or password. Please try again."
        } else if errorDescription.contains("Email not confirmed") {
            errorMessage = "Please check your email and confirm your account."
        } else {
            errorMessage = "Login failed: \(errorDescription)"
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
