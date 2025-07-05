import Foundation
import Supabase
import PostgREST
import Storage
import UIKit

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        // TODO: Replace with proper environment variable or configuration
        client = SupabaseClient(
            supabaseURL: URL(string: "https://lhtudqxldzwloyyxgvrx.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxodHVkcXhsZHp3bG95eXhndnJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5MDU3NTcsImV4cCI6MjA2NTQ4MTc1N30.Qh34YH6mEn-2y2GB1TZ64xMFyn4bbEsS3nw2mDlOlro"
        )
    }

    // ✅ Upload profile image and store public URL
    func uploadProfileImage(_ image: UIImage, for email: String) async throws -> String {
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
        let response = try await client
            .from("users")
            .select("photo_url")
            .eq("email", value: email)
            .single()
            .execute()

        // Decode the response properly
        let data = response.data
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let userData = try? JSONDecoder().decode([String: String?].self, from: jsonData) {
            return userData["photo_url"] ?? nil
        }
        
        return nil
    }
}
