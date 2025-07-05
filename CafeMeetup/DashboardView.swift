import SwiftUI
import MapKit

struct DashboardView: View {
    @Binding var isLoggedIn: Bool
    @Binding var firstName: String
    @Binding var userStatus: String
    
    @State private var currentUser: User?
    @State private var availableUsers: [User] = []
    @State private var pendingMatches: [Match] = []
    @State private var currentDateProposal: DateProposal?
    @State private var currentAttendance: Attendance?
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showDateSelection = false
    @State private var showAttendanceConfirmation = false
    @State private var confirmationCode = ""
    @State private var rejectionCount = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with user info
                headerSection
                
                // Current status section
                statusSection
                
                // Action buttons based on status
                actionButtonsSection
                
                // Messages section
                if !messages.isEmpty {
                    messagesSection
                }
                
                // Error display
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Cafe Meetup")
        .onAppear {
            loadUserData()
        }
        .refreshable {
            loadUserData()
        }
        .sheet(isPresented: $showDateSelection) {
            DateSelectionView(
                matchId: currentDateProposal?.matchId ?? "",
                proposerId: currentUser?.id ?? "",
                onDateProposalCreated: { proposal in
                    currentDateProposal = proposal
                    showDateSelection = false
                    loadUserData()
                }
            )
        }
        .sheet(isPresented: $showAttendanceConfirmation) {
            AttendanceConfirmationView(
                dateProposal: currentDateProposal!,
                onAttendanceConfirmed: {
                    showAttendanceConfirmation = false
                    loadUserData()
                }
            )
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            if let user = currentUser, let photoURL = user.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(Text("Photo"))
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(Text("Photo"))
            }
            
            Text("Welcome, \(firstName)!")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let user = currentUser, let location = user.location {
                Text(location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Status")
                .font(.headline)
            
            Text(statusDescription)
                .foregroundColor(.primary)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            switch UserStatus(rawValue: userStatus) {
            case .default:
                defaultButtons
            case .chooser:
                chooserButtons
            case .chosen:
                chosenButtons
            case .waitingForAcceptance:
                waitingForAcceptanceButtons
            case .waitingForDateSelection:
                waitingForDateSelectionButtons
            case .waitingForDateChoice:
                waitingForDateChoiceButtons
            case .waitingForConfirmation:
                waitingForConfirmationButtons
            case .dateConfirmed:
                dateConfirmedButtons
            case .waitingForAttendance:
                waitingForAttendanceButtons
            case .dateCompleted:
                dateCompletedButtons
            case .none:
                defaultButtons
            }
        }
    }
    
    // MARK: - Default Buttons (Be a Chooser or Be Chosen)
    private var defaultButtons: some View {
        VStack(spacing: 16) {
            Button("Be a Chooser") {
                updateUserStatus(.chooser)
            }
            .buttonStyle(.borderedProminent)
            .disabled(rejectionCount >= 3)
            
            Button("Be Chosen") {
                updateUserStatus(.chosen)
            }
            .buttonStyle(.borderedProminent)
            .disabled(rejectionCount >= 3)
            
            if rejectionCount >= 3 {
                Text("You've reached the daily rejection limit. Try again tomorrow!")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Chooser Buttons
    private var chooserButtons: some View {
        VStack(spacing: 16) {
            if availableUsers.isEmpty {
                Text("No available profiles at the moment. Check back later!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Refresh") {
                    loadUserData()
                }
                .buttonStyle(.bordered)
            } else {
                ForEach(availableUsers.prefix(3)) { user in
                    UserProfileCard(user: user) {
                        selectUser(user)
                    }
                }
            }
            
            Button("Back to Menu") {
                updateUserStatus(.default)
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Chosen Buttons
    private var chosenButtons: some View {
        VStack(spacing: 16) {
            Text("You're now visible to Choosers!")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Someone will choose you soon. You'll get a notification when they do.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Back to Menu") {
                updateUserStatus(.default)
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Waiting for Acceptance Buttons
    private var waitingForAcceptanceButtons: some View {
        VStack(spacing: 16) {
            if let match = pendingMatches.first {
                Text("You've been chosen!")
                    .font(.headline)
                
                if let chosenUser = getChosenUser(from: match) {
                    UserProfileCard(user: chosenUser) {
                        // Show user profile
                    }
                }
                
                HStack(spacing: 16) {
                    Button("Accept") {
                        respondToMatch(matchId: match.id, accepted: true)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Reject") {
                        respondToMatch(matchId: match.id, accepted: false)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    // MARK: - Waiting for Date Selection Buttons
    private var waitingForDateSelectionButtons: some View {
        VStack(spacing: 16) {
            Text("Your match accepted! Now select 3 date options.")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Button("Select Dates") {
                showDateSelection = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Waiting for Date Choice Buttons
    private var waitingForDateChoiceButtons: some View {
        VStack(spacing: 16) {
            Text("Waiting for your match to choose a date...")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Waiting for Confirmation Buttons
    private var waitingForConfirmationButtons: some View {
        VStack(spacing: 16) {
            if let proposal = currentDateProposal {
                Text("Your match selected a date!")
                    .font(.headline)
                
                let selectedIndex = proposal.selectedDateIndex ?? 0
                let selectedDate = [proposal.date1, proposal.date2, proposal.date3][selectedIndex]
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Date:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(selectedDate.displayText)
                        .font(.body)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                
                HStack(spacing: 16) {
                    Button("Confirm") {
                        confirmDate(dateProposalId: proposal.id)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Decline") {
                        // Handle decline
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    // MARK: - Date Confirmed Buttons
    private var dateConfirmedButtons: some View {
        VStack(spacing: 16) {
            if let proposal = currentDateProposal {
                let selectedIndex = proposal.selectedDateIndex ?? 0
                let selectedDate = [proposal.date1, proposal.date2, proposal.date3][selectedIndex]
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Date Confirmed!")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date: \(selectedDate.displayText)")
                        Text("Location: \(selectedDate.address)")
                    }
                    .font(.body)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                
                // Countdown timer would go here
                Text("Date starts in: 2 days, 14 hours")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Waiting for Attendance Buttons
    private var waitingForAttendanceButtons: some View {
        VStack(spacing: 16) {
            Text("Confirm you'll attend the date")
                .font(.headline)
            
            Button("I'll Be There") {
                showAttendanceConfirmation = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Date Completed Buttons
    private var dateCompletedButtons: some View {
        VStack(spacing: 16) {
            Text("Date completed! Rate your experience.")
                .font(.headline)
            
            HStack(spacing: 16) {
                Button("Would Meet Again") {
                    // Handle positive rating
                }
                .buttonStyle(.borderedProminent)
                
                Button("Not Interested") {
                    // Handle negative rating
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Messages Section
    private var messagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Messages")
                .font(.headline)
            
            ForEach(messages.prefix(3)) { message in
                MessageCard(message: message) {
                    markMessageAsRead(messageId: message.id)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    private var statusDescription: String {
        switch UserStatus(rawValue: userStatus) {
        case .default: return "Ready to start your dating journey! Choose to be a Chooser or be Chosen."
        case .chooser: return "You're browsing profiles to choose someone to meet."
        case .chosen: return "You're waiting to be picked by a Chooser."
        case .waitingForAcceptance: return "You've been chosen! Accept or reject the match."
        case .waitingForDateSelection: return "Your match accepted! Select 3 date options."
        case .waitingForDateChoice: return "Waiting for your match to choose from your date options."
        case .waitingForConfirmation: return "Your match selected a date! Confirm to proceed."
        case .dateConfirmed: return "Date confirmed! Get ready for your meetup."
        case .waitingForAttendance: return "Confirm your attendance for the upcoming date."
        case .dateCompleted: return "Date completed! Rate your experience."
        case .none: return "Unknown status"
        }
    }
    
    // MARK: - Helper Methods
    private func getChosenUser(from match: Match) -> User? {
        // This would need to be implemented to fetch the chosen user's profile
        return nil
    }
    
    // MARK: - Data Loading
    private func loadUserData() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Load current user
                currentUser = try await SupabaseManager.shared.getCurrentUser()
                
                // Load rejection count
                if let user = currentUser {
                    rejectionCount = try await SupabaseManager.shared.getRejectionCount(for: user.id)
                    try await SupabaseManager.shared.resetRejectionCountIfNeeded(for: user.id)
                    
                    // Load available users if chooser
                    if user.status == .chooser {
                        availableUsers = try await SupabaseManager.shared.getAvailableChosenUsers(for: user.email)
                    }
                    
                    // Load pending matches
                    pendingMatches = try await SupabaseManager.shared.getPendingMatches(for: user.id)
                    
                    // Load messages
                    messages = try await SupabaseManager.shared.getMessages(for: user.id)
                }
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load data: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Actions
    private func updateUserStatus(_ status: UserStatus) {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                guard let email = try await SupabaseManager.shared.client.auth.session.user.email else {
                    await MainActor.run {
                        errorMessage = "No email found"
                        isLoading = false
                    }
                    return
                }
                
                try await SupabaseManager.shared.updateUserStatus(status, for: email)
                
                await MainActor.run {
                    userStatus = status.rawValue
                    isLoading = false
                    loadUserData()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update status: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func selectUser(_ user: User) {
        Task {
            do {
                guard let currentUser = currentUser else { return }
                
                let match = try await SupabaseManager.shared.createMatch(
                    chooserId: currentUser.id,
                    chosenId: user.id
                )
                
                // Send notification to chosen user
                try await SupabaseManager.shared.createMessage(
                    userId: user.id,
                    title: "You've been chosen!",
                    body: "\(currentUser.firstName) has chosen you for a potential meetup. Check your dashboard to accept or reject.",
                    type: .match
                )
                
                await MainActor.run {
                    updateUserStatus(.waitingForAcceptance)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to select user: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func respondToMatch(matchId: String, accepted: Bool) {
        Task {
            do {
                try await SupabaseManager.shared.respondToMatch(matchId: matchId, accepted: accepted)
                
                if accepted {
                    await MainActor.run {
                        updateUserStatus(.waitingForDateSelection)
                    }
                } else {
                    await MainActor.run {
                        updateUserStatus(.default)
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to respond to match: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func confirmDate(dateProposalId: String) {
        Task {
            do {
                try await SupabaseManager.shared.confirmDate(dateProposalId: dateProposalId)
                
                await MainActor.run {
                    updateUserStatus(.dateConfirmed)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to confirm date: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func markMessageAsRead(messageId: String) {
        Task {
            do {
                try await SupabaseManager.shared.markMessageAsRead(messageId: messageId)
                await MainActor.run {
                    loadUserData()
                }
            } catch {
                print("Failed to mark message as read: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views
struct UserProfileCard: View {
    let user: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let photoURL = user.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(Text("Photo"))
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(Text("Photo"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(user.firstName) \(user.lastName)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let location = user.location {
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let bio = user.bio {
                        Text(bio)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MessageCard: View {
    let message: Message
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(message.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !message.read {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(message.body)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                Text(message.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(message.read ? Color.clear : Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
