import SwiftUI
import PhotosUI

struct AccountView: View {
    @Binding var isLoggedIn: Bool
    @State private var profileImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var userEmail = "" // You should set this after login

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 150)
                    .overlay(Text("No Photo"))
            }

            Button("Change Photo") {
                showPhotoPicker = true
            }

            Button("Log Out") {
                isLoggedIn = false
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .cornerRadius(10)

            Spacer()
        }
        .padding()
        .onAppear {
            fetchProfileImage()
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImage: $profileImage) { image in
                Task {
                    let image = image
                    do {
                        _ = try await SupabaseManager.shared.uploadProfileImage(image, for: userEmail)
                    } catch {
                        print("Upload failed: \(error)")
                    }
                }
            }
        }
    }

    func fetchProfileImage() {
        Task {
            do {
                let url = try await SupabaseManager.shared.fetchUserPhotoURL(for: userEmail)
                if let url = url, let imageURL = URL(string: url),
                   let data = try? Data(contentsOf: imageURL),
                   let image = UIImage(data: data) {
                    profileImage = image
                }
            } catch {
                print("Error fetching profile image: \(error)")
            }
        }
    }
}
