import Foundation
import Supabase
import PostgREST
import Storage
import UIKit

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://lhtudqxldzwloyyxgvrx.supabase.co")!,
            supabaseKey: "your-key-here"
        )
    }

    // ✅ Upload profile image and store public URL
    func uploadProfileImage(_ image: UIImage, email: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image conversion failed"])
        }

        let fileName = email.replacingOccurrences(of: "@", with: "_").replacingOccurrences(of: ".", with: "_") + ".jpg"

        // ✅ Use correct .upload(file:) method (no path:) — it's renamed
        _ = try await client.storage
            .from("profile-photos")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )

        let publicURL = "https://lhtudqxldzwloyyxgvrx.supabase.co/storage/v1/object/public/profile-photos/\(fileName)"

        // ✅ Save the URL in the users table
        _ = try await client
            .from("users")
            .update(["photo_url": publicURL])
            .eq("email", value: email)
            .execute()

        return publicURL
    }

    // ✅ Fetch stored photo URL
    func fetchUserPhotoURL(for email: String) async throws -> String? {
        struct UserPhoto: Decodable {
            let photo_url: String?
        }

        let response = try await client
            .from("users")
            .select("photo_url")
            .eq("email", value: email)
            .single()
            .value as? [String: Any]

        return response?["photo_url"] as? String
    }
}
