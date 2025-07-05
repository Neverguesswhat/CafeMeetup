import SwiftUI

struct ProfilePhotoView: View {
    let email: String
    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else if isLoading {
                ProgressView()
                    .frame(width: 80, height: 80)
            } else {
                // fallback if no image
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
            }
        }
        .onAppear {
            loadProfilePhoto()
        }
    }

    private func loadProfilePhoto() {
        Task {
            do {
                if let urlString = try await SupabaseManager.shared.fetchUserPhotoURL(for: email),
                   let url = URL(string: urlString) {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            self.image = uiImage
                        }
                    }
                }
            } catch {
                print("Failed to load profile photo: \(error.localizedDescription)")
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }
}
