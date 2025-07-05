import SwiftUI

struct DashboardView: View {
    @Binding var isLoggedIn: Bool
    @Binding var firstName: String
    @Binding var userStatus: String

    @State private var isSavingStatus = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 🟦 CURRENT MEETUP SECTION
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Meetup")
                            .font(.headline)

                        Text(meetupDescription)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                    // 🟦 BUTTONS WHEN DEFAULT
                    if userStatus == "default" {
                        VStack(spacing: 16) {
                            Button("Be a Chooser") {
                                updateUserStatus(to: "chooser")
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Be Chosen") {
                                updateUserStatus(to: "chosen")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    // 🟦 WELCOME
                    Text("Welcome to Meetups, \(firstName)!")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    // 🟦 ERROR
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Meetups")
        }
    }

    // ✅ STATUS UPDATE FUNCTION
    func updateUserStatus(to newStatus: String) {
        isSavingStatus = true
        errorMessage = ""

        Task {
            do {
                guard let email = try await SupabaseManager.shared.client.auth.session.user.email else {
                    await MainActor.run {
                        errorMessage = "No email found"
                        isSavingStatus = false
                    }
                    return
                }

                try await SupabaseManager.shared.client
                    .from("users")
                    .update(["status": newStatus])
                    .eq("email", value: email)
                    .execute()

                await MainActor.run {
                    userStatus = newStatus
                    isSavingStatus = false
                }

            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update status: \(error.localizedDescription)"
                    isSavingStatus = false
                }
            }
        }
    }

    // 🟦 MEETUP DESCRIPTION
    var meetupDescription: String {
        switch userStatus {
        case "default": return "You haven’t started a meetup journey yet. Choose or be chosen to begin!"
        case "chooser": return "You’re browsing profiles to choose someone to meet."
        case "chosen": return "You’re waiting to be picked by a Chooser."
        default: return "You're currently: \(userStatus)"
        }
    }
}
