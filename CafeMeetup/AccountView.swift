import SwiftUI
import PhotosUI

struct AccountView: View {
    @Binding var isLoggedIn: Bool
    @State private var profileImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var userEmail = ""
    @State private var currentUser: User?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showLocationPicker = false
    @State private var showBioEditor = false
    @State private var tempLocation = ""
    @State private var tempBio = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Photo Section
                    profilePhotoSection
                    
                    // User Info Section
                    userInfoSection
                    
                    // Settings Section
                    settingsSection
                    
                    // Log Out Section
                    logOutSection
                    
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
            .navigationTitle("Account")
            .onAppear {
                loadUserData()
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(selectedImage: $profileImage) { image in
                    uploadProfileImage(image)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(location: $tempLocation) { location in
                    updateUserLocation(location)
                }
            }
            .sheet(isPresented: $showBioEditor) {
                BioEditorView(bio: $tempBio) { bio in
                    updateUserBio(bio)
                }
            }
        }
    }
    
    // MARK: - Profile Photo Section
    private var profilePhotoSection: some View {
        VStack(spacing: 16) {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 3)
                    )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        VStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No Photo")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
            
            Button("Change Photo") {
                showPhotoPicker = true
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - User Info Section
    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if let user = currentUser {
                    InfoRow(title: "Name", value: "\(user.firstName) \(user.lastName)")
                    InfoRow(title: "Email", value: user.email)
                    
                    if let location = user.location {
                        InfoRow(title: "Location", value: location)
                    } else {
                        Button("Add Location") {
                            tempLocation = ""
                            showLocationPicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let bio = user.bio {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(bio)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button("Add Bio") {
                            tempBio = ""
                            showBioEditor = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if let user = currentUser {
                    Button(action: {
                        tempLocation = user.location ?? ""
                        showLocationPicker = true
                    }) {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.blue)
                            Text("Edit Location")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        tempBio = user.bio ?? ""
                        showBioEditor = true
                    }) {
                        HStack {
                            Image(systemName: "text.quote")
                                .foregroundColor(.green)
                            Text("Edit Bio")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        // Handle notification settings
                    }) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.orange)
                            Text("Notification Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        // Handle privacy settings
                    }) {
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.purple)
                            Text("Privacy Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Log Out Section
    private var logOutSection: some View {
        VStack(spacing: 16) {
            Button("Log Out") {
                logOut()
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .cornerRadius(10)
            
            Button("Delete Account") {
                // Handle account deletion
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Helper Views
    private func InfoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Data Loading
    private func loadUserData() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                currentUser = try await SupabaseManager.shared.getCurrentUser()
                
                if let user = currentUser {
                    userEmail = user.email
                    
                    // Load profile image
                    if let photoURL = user.photoURL, let url = URL(string: photoURL) {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let image = UIImage(data: data) {
                            await MainActor.run {
                                profileImage = image
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load user data: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Actions
    private func uploadProfileImage(_ image: UIImage) {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                _ = try await SupabaseManager.shared.uploadProfileImage(image, for: userEmail)
                
                await MainActor.run {
                    profileImage = image
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func updateUserLocation(_ location: String) {
        Task {
            do {
                try await SupabaseManager.shared.updateUserLocation(location, for: userEmail)
                await MainActor.run {
                    loadUserData()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update location: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func updateUserBio(_ bio: String) {
        Task {
            do {
                // This would need to be implemented in SupabaseManager
                // For now, we'll just update the local state
                await MainActor.run {
                    loadUserData()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update bio: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func logOut() {
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signOut()
                await MainActor.run {
                    isLoggedIn = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to log out: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Location Picker View
struct LocationPickerView: View {
    @Binding var location: String
    let onLocationSelected: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    private let locationOptions = [
        "Beaverton, OR",
        "Gresham, OR",
        "Portland, OR",
        "Lake Oswego, OR",
        "Tigard, OR",
        "Hillsboro, OR",
        "West Linn, OR",
        "Tualatin, OR",
        "Wilsonville, OR",
        "Happy Valley, OR"
    ]
    
    var filteredLocations: [String] {
        if searchText.isEmpty {
            return locationOptions
        } else {
            return locationOptions.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, placeholder: "Search locations...")
                
                List(filteredLocations, id: \.self) { location in
                    Button(action: {
                        onLocationSelected(location)
                        dismiss()
                    }) {
                        HStack {
                            Text(location)
                                .foregroundColor(.primary)
                            Spacer()
                            if location == self.location {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Location")
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

// MARK: - Bio Editor View
struct BioEditorView: View {
    @Binding var bio: String
    let onBioSaved: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempBio = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Tell us about yourself")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Share a bit about yourself to help others get to know you better.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                TextField("Write your bio here...", text: $tempBio, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(5...10)
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Bio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onBioSaved(tempBio)
                        dismiss()
                    }
                    .disabled(tempBio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                tempBio = bio
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
