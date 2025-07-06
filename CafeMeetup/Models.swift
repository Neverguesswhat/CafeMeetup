import Foundation
import SwiftUI

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: String
    let first_name: String
    let last_name: String
    let email: String
    let created_at: String
    let status: String
    let photo_url: String?
    let location: String?
    let bio: String?
    let last_active_at: String?
    
    enum CodingKeys: String, CodingKey {
        case id, first_name, last_name, email, created_at, status, photo_url, location, bio, last_active_at
    }
}

enum UserStatus: String, Codable, CaseIterable {
    case `default` = "default"
    case chooser = "chooser"
    case chosen = "chosen"
    case waitingForAcceptance = "waiting_for_acceptance"
    case waitingForDateSelection = "waiting_for_date_selection"
    case waitingForDateChoice = "waiting_for_date_choice"
    case waitingForConfirmation = "waiting_for_confirmation"
    case dateConfirmed = "date_confirmed"
    case waitingForAttendance = "waiting_for_attendance"
    case dateCompleted = "date_completed"
    
    var displayName: String {
        switch self {
        case .default: return "Ready to Start"
        case .chooser: return "Choosing"
        case .chosen: return "Waiting to be Chosen"
        case .waitingForAcceptance: return "Waiting for Response"
        case .waitingForDateSelection: return "Selecting Dates"
        case .waitingForDateChoice: return "Waiting for Date Choice"
        case .waitingForConfirmation: return "Confirming Date"
        case .dateConfirmed: return "Date Confirmed"
        case .waitingForAttendance: return "Confirming Attendance"
        case .dateCompleted: return "Date Completed"
        }
    }
}

// MARK: - Match Model
struct Match: Identifiable, Codable {
    let id: String
    let chooserId: String
    let chosenId: String
    let status: MatchStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, chooserId = "chooser_id", chosenId = "chosen_id", status, createdAt = "created_at", updatedAt = "updated_at"
    }
}

enum MatchStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case expired = "expired"
}

// MARK: - Date Model
struct DateProposal: Identifiable, Codable {
    let id: String
    let matchId: String
    let proposerId: String
    let date1: DateOption
    let date2: DateOption
    let date3: DateOption
    let selectedDateIndex: Int?
    let status: DateStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, matchId = "match_id", proposerId = "proposer_id", date1, date2, date3, selectedDateIndex = "selected_date_index", status, createdAt = "created_at", updatedAt = "updated_at"
    }
}

struct DateOption: Codable {
    var date: Date
    var time: Date
    var location: String
    var venueName: String
    var address: String
    var latitude: Double?
    var longitude: Double?
    
    var fullDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        return calendar.date(from: combinedComponents) ?? date
    }
    
    var displayText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return "\(dateFormatter.string(from: fullDateTime)) at \(venueName)"
    }
}

enum DateStatus: String, Codable {
    case proposed = "proposed"
    case selected = "selected"
    case confirmed = "confirmed"
    case cancelled = "cancelled"
}

// MARK: - Attendance Model
struct Attendance: Identifiable, Codable {
    let id: String
    let dateId: String
    let userId: String
    let confirmed: Bool
    let confirmationCode: String?
    let confirmedAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, dateId = "date_id", userId = "user_id", confirmed, confirmationCode = "confirmation_code", confirmedAt = "confirmed_at", createdAt = "created_at"
    }
}

// MARK: - Rating Model
struct Rating: Identifiable, Codable {
    let id: String
    let dateId: String
    let raterId: String
    let ratedId: String
    let wouldMeetAgain: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, dateId = "date_id", raterId = "rater_id", ratedId = "rated_id", wouldMeetAgain = "would_meet_again", createdAt = "created_at"
    }
}

// MARK: - Black Book Entry
struct BlackBookEntry: Identifiable, Codable {
    let id: String
    let userId: String
    let contactId: String
    let contactName: String
    let contactEmail: String?
    let contactPhone: String?
    let notes: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", contactId = "contact_id", contactName = "contact_name", contactEmail = "contact_email", contactPhone = "contact_phone", notes, createdAt = "created_at"
    }
}

// MARK: - Message Model
struct Message: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let body: String
    let type: MessageType
    let read: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", title, body, type, read, createdAt = "created_at"
    }
}

enum MessageType: String, Codable {
    case match = "match"
    case dateProposal = "date_proposal"
    case dateConfirmation = "date_confirmation"
    case attendance = "attendance"
    case reminder = "reminder"
    case system = "system"
}

// MARK: - Rejection Tracking
struct RejectionCount: Identifiable, Codable {
    let id: String
    let userId: String
    let count: Int
    let lastResetDate: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", count, lastResetDate = "last_reset_date"
    }
} 