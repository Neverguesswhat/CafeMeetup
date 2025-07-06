import SwiftUI

struct MessagesView: View {
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var currentUser: User?
    @State private var selectedMessage: Message?
    @State private var showMessageDetail = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading messages...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if messages.isEmpty {
                emptyStateView
            } else {
                messagesListView
            }
        }
        .navigationTitle("Messages")
        .onAppear {
            loadMessages()
        }
        .refreshable {
            loadMessages()
        }
        .sheet(isPresented: $showMessageDetail) {
            if let message = selectedMessage {
                MessageDetailView(message: message) {
                    markMessageAsRead(messageId: message.id)
                }
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "message")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("No Messages Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("You'll receive notifications here when someone chooses you, accepts your match, or when there are updates about your dates.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Messages List View
    private var messagesListView: some View {
        List {
            ForEach(messages) { message in
                MessageRowView(message: message) {
                    selectedMessage = message
                    showMessageDetail = true
                }
            }
            .onDelete(perform: deleteMessage)
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Data Loading
    private func loadMessages() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if currentUser == nil {
                    currentUser = try await SupabaseManager.shared.getCurrentUser()
                }
                
                if let user = currentUser {
                    messages = try await SupabaseManager.shared.getMessages(for: user.id)
                }
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load messages: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Actions
    private func markMessageAsRead(messageId: String) {
        Task {
            do {
                try await SupabaseManager.shared.markMessageAsRead(messageId: messageId)
                await MainActor.run {
                    loadMessages()
                }
            } catch {
                print("Failed to mark message as read: \(error)")
            }
        }
    }
    
    private func deleteMessage(at offsets: IndexSet) {
        // This would need to be implemented to delete from Supabase
        // For now, just remove from local array
        messages.remove(atOffsets: offsets)
    }
}

// MARK: - Message Row View
struct MessageRowView: View {
    let message: Message
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Message type icon
                Image(systemName: iconForMessageType(message.type))
                    .font(.title2)
                    .foregroundColor(colorForMessageType(message.type))
                    .frame(width: 40, height: 40)
                    .background(colorForMessageType(message.type).opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(message.title)
                            .font(.headline)
                            .fontWeight(.semibold)
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
                        .lineLimit(2)
                    
                    Text(message.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForMessageType(_ type: MessageType) -> String {
        switch type {
        case .match:
            return "heart.fill"
        case .dateProposal:
            return "calendar"
        case .dateConfirmation:
            return "checkmark.circle.fill"
        case .attendance:
            return "person.2.fill"
        case .reminder:
            return "bell.fill"
        case .system:
            return "info.circle.fill"
        }
    }
    
    private func colorForMessageType(_ type: MessageType) -> Color {
        switch type {
        case .match:
            return .pink
        case .dateProposal:
            return .blue
        case .dateConfirmation:
            return .green
        case .attendance:
            return .orange
        case .reminder:
            return .purple
        case .system:
            return .gray
        }
    }
}

// MARK: - Message Detail View
struct MessageDetailView: View {
    let message: Message
    let onMarkAsRead: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: iconForMessageType(message.type))
                            .font(.title)
                            .foregroundColor(colorForMessageType(message.type))
                            .frame(width: 50, height: 50)
                            .background(colorForMessageType(message.type).opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(message.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Message body
                VStack(alignment: .leading, spacing: 16) {
                    Text("Message")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(message.body)
                        .font(.body)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                
                // Action buttons based on message type
                if !message.read {
                    Button(action: {
                        onMarkAsRead()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Mark as Read")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Message")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func iconForMessageType(_ type: MessageType) -> String {
        switch type {
        case .match:
            return "heart.fill"
        case .dateProposal:
            return "calendar"
        case .dateConfirmation:
            return "checkmark.circle.fill"
        case .attendance:
            return "person.2.fill"
        case .reminder:
            return "bell.fill"
        case .system:
            return "info.circle.fill"
        }
    }
    
    private func colorForMessageType(_ type: MessageType) -> Color {
        switch type {
        case .match:
            return .pink
        case .dateProposal:
            return .blue
        case .dateConfirmation:
            return .green
        case .attendance:
            return .orange
        case .reminder:
            return .purple
        case .system:
            return .gray
        }
    }
} 