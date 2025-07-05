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

    // MARK: - Profile Image Management
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
        struct UpdatePhoto: Encodable { let photo_url: String }
        _ = try await client
            .from("users")
            .update(UpdatePhoto(photo_url: publicURL))
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
        if let userData = try? JSONDecoder().decode([String: String?].self, from: data) {
            return userData["photo_url"] ?? nil
        }
        
        return nil
    }

    // MARK: - User Management
    func getCurrentUser() async throws -> User? {
        guard let email = try await client.auth.session.user.email else {
            return nil
        }
        
        let response = try await client
            .from("users")
            .select("*")
            .eq("email", value: email)
            .single()
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    func updateUserStatus(_ status: UserStatus, for email: String) async throws {
        struct UpdateStatus: Encodable { let status: String }
        _ = try await client
            .from("users")
            .update(UpdateStatus(status: status.rawValue))
            .eq("email", value: email)
            .execute()
    }
    
    func updateUserLocation(_ location: String, for email: String) async throws {
        struct UpdateLocation: Encodable { let location: String }
        _ = try await client
            .from("users")
            .update(UpdateLocation(location: location))
            .eq("email", value: email)
            .execute()
    }

    // MARK: - Matching System
    func getAvailableChosenUsers(for chooserEmail: String) async throws -> [User] {
        let response = try await client
            .from("users")
            .select("*")
            .eq("status", value: UserStatus.chosen.rawValue)
            .neq("email", value: chooserEmail)
            .limit(10)
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode([User].self, from: data)
    }
    
    func createMatch(chooserId: String, chosenId: String) async throws -> Match {
        struct MatchInsert: Encodable {
            let chooser_id: String
            let chosen_id: String
            let status: String
        }
        let matchData = MatchInsert(chooser_id: chooserId, chosen_id: chosenId, status: MatchStatus.pending.rawValue)
        
        let response = try await client
            .from("matches")
            .insert(matchData)
            .select()
            .single()
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode(Match.self, from: data)
    }
    
    func respondToMatch(matchId: String, accepted: Bool) async throws {
        struct UpdateMatch: Encodable { let status: String }
        let status = accepted ? MatchStatus.accepted.rawValue : MatchStatus.rejected.rawValue
        _ = try await client
            .from("matches")
            .update(UpdateMatch(status: status))
            .eq("id", value: matchId)
            .execute()
    }
    
    func getPendingMatches(for userId: String) async throws -> [Match] {
        let response = try await client
            .from("matches")
            .select("*")
            .or("chooser_id.eq.\(userId),chosen_id.eq.\(userId)")
            .eq("status", value: MatchStatus.pending.rawValue)
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode([Match].self, from: data)
    }

    // MARK: - Date Proposals
    func createDateProposal(matchId: String, proposerId: String, date1: DateOption, date2: DateOption, date3: DateOption) async throws -> DateProposal {
        struct DateProposalInsert: Encodable {
            let match_id: String
            let proposer_id: String
            let date1: DateOption
            let date2: DateOption
            let date3: DateOption
            let status: String
        }
        let dateData = DateProposalInsert(
            match_id: matchId,
            proposer_id: proposerId,
            date1: date1,
            date2: date2,
            date3: date3,
            status: DateStatus.proposed.rawValue
        )
        
        let response = try await client
            .from("date_proposals")
            .insert(dateData)
            .select()
            .single()
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode(DateProposal.self, from: data)
    }
    
    func selectDate(dateProposalId: String, selectedIndex: Int) async throws {
        struct UpdateDate: Encodable { let selected_date_index: Int; let status: String }
        _ = try await client
            .from("date_proposals")
            .update(UpdateDate(selected_date_index: selectedIndex, status: DateStatus.selected.rawValue))
            .eq("id", value: dateProposalId)
            .execute()
    }
    
    func confirmDate(dateProposalId: String) async throws {
        struct UpdateDate: Encodable { let status: String }
        _ = try await client
            .from("date_proposals")
            .update(UpdateDate(status: DateStatus.confirmed.rawValue))
            .eq("id", value: dateProposalId)
            .execute()
    }

    // MARK: - Attendance Tracking
    func createAttendanceRecord(dateId: String, userId: String) async throws -> Attendance {
        struct AttendanceInsert: Encodable {
            let date_id: String
            let user_id: String
            let confirmed: Bool
            let confirmation_code: String
        }
        let confirmationCode = String(format: "%04d", Int.random(in: 1000...9999))
        let attendanceData = AttendanceInsert(date_id: dateId, user_id: userId, confirmed: false, confirmation_code: confirmationCode)
        
        let response = try await client
            .from("attendance")
            .insert(attendanceData)
            .select()
            .single()
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode(Attendance.self, from: data)
    }
    
    func confirmAttendance(attendanceId: String) async throws {
        struct UpdateAttendance: Encodable { let confirmed: Bool; let confirmed_at: String }
        _ = try await client
            .from("attendance")
            .update(UpdateAttendance(confirmed: true, confirmed_at: ISO8601DateFormatter().string(from: Date())))
            .eq("id", value: attendanceId)
            .execute()
    }
    
    func verifyConfirmationCode(dateId: String, code: String) async throws -> Bool {
        let response = try await client
            .from("attendance")
            .select("confirmation_code")
            .eq("date_id", value: dateId)
            .eq("confirmation_code", value: code)
            .execute()
        
        return !response.data.isEmpty
    }

    // MARK: - Rating System
    func rateDate(dateId: String, raterId: String, ratedId: String, wouldMeetAgain: Bool) async throws {
        struct RatingInsert: Encodable {
            let date_id: String
            let rater_id: String
            let rated_id: String
            let would_meet_again: Bool
        }
        let ratingData = RatingInsert(date_id: dateId, rater_id: raterId, rated_id: ratedId, would_meet_again: wouldMeetAgain)
        
        _ = try await client
            .from("ratings")
            .insert(ratingData)
            .execute()
    }

    // MARK: - Black Book
    func addToBlackBook(userId: String, contactId: String, contactName: String, contactEmail: String?, contactPhone: String?, notes: String?) async throws {
        struct BlackBookInsert: Encodable {
            let user_id: String
            let contact_id: String
            let contact_name: String
            let contact_email: String?
            let contact_phone: String?
            let notes: String?
        }
        let blackBookData = BlackBookInsert(
            user_id: userId,
            contact_id: contactId,
            contact_name: contactName,
            contact_email: contactEmail,
            contact_phone: contactPhone,
            notes: notes
        )
        
        _ = try await client
            .from("black_book")
            .insert(blackBookData)
            .execute()
    }
    
    func getBlackBookEntries(for userId: String) async throws -> [BlackBookEntry] {
        let response = try await client
            .from("black_book")
            .select("*")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode([BlackBookEntry].self, from: data)
    }

    // MARK: - Messaging
    func createMessage(userId: String, title: String, body: String, type: MessageType) async throws {
        struct MessageInsert: Encodable {
            let user_id: String
            let title: String
            let body: String
            let type: String
            let read: Bool
        }
        let messageData = MessageInsert(user_id: userId, title: title, body: body, type: type.rawValue, read: false)
        
        _ = try await client
            .from("messages")
            .insert(messageData)
            .execute()
    }
    
    func getMessages(for userId: String) async throws -> [Message] {
        let response = try await client
            .from("messages")
            .select("*")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode([Message].self, from: data)
    }
    
    func markMessageAsRead(messageId: String) async throws {
        struct UpdateMessage: Encodable { let read: Bool }
        _ = try await client
            .from("messages")
            .update(UpdateMessage(read: true))
            .eq("id", value: messageId)
            .execute()
    }

    // MARK: - Rejection Tracking
    func getRejectionCount(for userId: String) async throws -> Int {
        let response = try await client
            .from("rejection_counts")
            .select("count")
            .eq("user_id", value: userId)
            .single()
            .execute()
        let data = response.data
        struct RejectionCountRow: Decodable { let count: Int }
        if let row = try? JSONDecoder().decode(RejectionCountRow.self, from: data) {
            return row.count
        }
        return 0
    }
    
    func incrementRejectionCount(for userId: String) async throws {
        struct RejectionCountUpsert: Encodable {
            let user_id: String
            let count: Int
            let last_reset_date: String
        }
        let currentCount = try await getRejectionCount(for: userId)
        let newCount = currentCount + 1
        let upsertData = RejectionCountUpsert(user_id: userId, count: newCount, last_reset_date: ISO8601DateFormatter().string(from: Date()))
        _ = try await client
            .from("rejection_counts")
            .upsert(upsertData)
            .execute()
    }
    
    func resetRejectionCountIfNeeded(for userId: String) async throws {
        let response = try await client
            .from("rejection_counts")
            .select("last_reset_date")
            .eq("user_id", value: userId)
            .single()
            .execute()
        let data = response.data
        struct LastResetRow: Decodable { let last_reset_date: String }
        if let row = try? JSONDecoder().decode(LastResetRow.self, from: data) {
            let lastResetString = row.last_reset_date
            if let lastReset = ISO8601DateFormatter().date(from: lastResetString) {
                let calendar = Calendar.current
                let daysSinceReset = calendar.dateComponents([.day], from: lastReset, to: Date()).day ?? 0
                if daysSinceReset >= 1 {
                    struct RejectionCountUpdate: Encodable {
                        let count: Int
                        let last_reset_date: String
                    }
                    let updateData = RejectionCountUpdate(count: 0, last_reset_date: ISO8601DateFormatter().string(from: Date()))
                    _ = try await client
                        .from("rejection_counts")
                        .update(updateData)
                        .eq("user_id", value: userId)
                        .execute()
                }
            }
        }
    }
}
