import SwiftUI
import CoreImage.CIFilterBuiltins

struct BlackBookView: View {
    @State private var blackBookEntries: [BlackBookEntry] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showAddContact = false
    @State private var showQRScanner = false
    @State private var currentUser: User?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading contacts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if blackBookEntries.isEmpty {
                emptyStateView
            } else {
                contactsListView
            }
        }
        .navigationTitle("Black Book")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showAddContact = true
                    }) {
                        Label("Add Contact", systemImage: "person.badge.plus")
                    }
                    
                    Button(action: {
                        showQRScanner = true
                    }) {
                        Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            loadBlackBookEntries()
        }
        .refreshable {
            loadBlackBookEntries()
        }
        .sheet(isPresented: $showAddContact) {
            AddContactView { contact in
                addContact(contact)
            }
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerView { scannedData in
                handleScannedData(scannedData)
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("Your Black Book is Empty")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add contacts from successful dates to keep in touch with people you've met.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    showAddContact = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Add Contact Manually")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showQRScanner = true
                }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Scan QR Code")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Contacts List View
    private var contactsListView: some View {
        List {
            ForEach(blackBookEntries) { entry in
                ContactRowView(entry: entry)
            }
            .onDelete(perform: deleteContact)
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Contact Row View
    private var contactRowView: some View {
        ForEach(blackBookEntries) { entry in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.contactName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let email = entry.contactEmail {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let phone = entry.contactPhone {
                            Text(phone)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(entry.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Data Loading
    private func loadBlackBookEntries() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if currentUser == nil {
                    currentUser = try await SupabaseManager.shared.getCurrentUser()
                }
                
                if let user = currentUser {
                    blackBookEntries = try await SupabaseManager.shared.getBlackBookEntries(for: user.id)
                }
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load contacts: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Actions
    private func addContact(_ contact: (name: String, email: String?, phone: String?, notes: String?)) {
        Task {
            do {
                guard let user = currentUser else { return }
                
                try await SupabaseManager.shared.addToBlackBook(
                    userId: user.id,
                    contactId: UUID().uuidString,
                    contactName: contact.name,
                    contactEmail: contact.email,
                    contactPhone: contact.phone,
                    notes: contact.notes
                )
                
                await MainActor.run {
                    loadBlackBookEntries()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to add contact: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func handleScannedData(_ data: String) {
        // Parse QR code data (assuming format: "name|email|phone|notes")
        let components = data.components(separatedBy: "|")
        
        if components.count >= 1 {
            let name = components[0]
            let email = components.count > 1 ? components[1] : nil
            let phone = components.count > 2 ? components[2] : nil
            let notes = components.count > 3 ? components[3] : nil
            
            addContact((name: name, email: email, phone: phone, notes: notes))
        }
    }
    
    private func deleteContact(at offsets: IndexSet) {
        // This would need to be implemented to delete from Supabase
        // For now, just remove from local array
        blackBookEntries.remove(atOffsets: offsets)
    }
}

// MARK: - Contact Row View
struct ContactRowView: View {
    let entry: BlackBookEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.contactName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let email = entry.contactEmail {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let phone = entry.contactPhone {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(entry.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Contact View
struct AddContactView: View {
    let onContactAdded: ((name: String, email: String?, phone: String?, notes: String?)) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var notes = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Email (Optional)", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone (Optional)", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Notes")) {
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveContact()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
    }
    
    private func saveContact() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Name is required"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        onContactAdded((name: trimmedName, email: trimmedEmail, phone: trimmedPhone, notes: trimmedNotes))
        
        isLoading = false
        dismiss()
    }
}

// MARK: - QR Scanner View (Placeholder)
struct QRScannerView: View {
    let onCodeScanned: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                
                Text("QR Code Scanner")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Point your camera at a QR code to scan contact information.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Placeholder for actual QR scanning functionality
                Button("Simulate Scan") {
                    // Simulate scanning a QR code
                    let mockData = "John Doe|john@example.com|555-1234|Met at Kennedy School"
                    onCodeScanned(mockData)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
} 