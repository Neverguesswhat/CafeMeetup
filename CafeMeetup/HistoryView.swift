import SwiftUI

struct HistoryView: View {
    @State private var completedDates: [DateProposal] = []
    @State private var ratings: [Rating] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var currentUser: User?
    @State private var selectedFilter: HistoryFilter = .all
    
    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case dates = "Dates"
        case ratings = "Ratings"
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading history...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if completedDates.isEmpty && ratings.isEmpty {
                    emptyStateView
                } else {
                    historyContentView
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(HistoryFilter.allCases, id: \.self) { filter in
                            Button(filter.rawValue) {
                                selectedFilter = filter
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .onAppear {
                loadHistory()
            }
            .refreshable {
                loadHistory()
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("No History Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Your completed dates and ratings will appear here once you've been on some dates.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    // MARK: - History Content View
    private var historyContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Filter buttons
                filterButtons
                
                // Content based on filter
                switch selectedFilter {
                case .all:
                    allHistoryContent
                case .dates:
                    datesHistoryContent
                case .ratings:
                    ratingsHistoryContent
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
    }
    
    // MARK: - Filter Buttons
    private var filterButtons: some View {
        HStack(spacing: 12) {
            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                Button(action: {
                    selectedFilter = filter
                }) {
                    Text(filter.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedFilter == filter ? Color.blue : Color(UIColor.systemGray5))
                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                        .cornerRadius(20)
                }
            }
        }
    }
    
    // MARK: - All History Content
    private var allHistoryContent: some View {
        VStack(spacing: 20) {
            if !completedDates.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Completed Dates")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(completedDates.prefix(5)) { date in
                        DateHistoryCard(date: date)
                    }
                }
            }
            
            if !ratings.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Ratings")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(ratings.prefix(5)) { rating in
                        RatingHistoryCard(rating: rating)
                    }
                }
            }
        }
    }
    
    // MARK: - Dates History Content
    private var datesHistoryContent: some View {
        VStack(spacing: 16) {
            if completedDates.isEmpty {
                Text("No completed dates yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(completedDates) { date in
                    DateHistoryCard(date: date)
                }
            }
        }
    }
    
    // MARK: - Ratings History Content
    private var ratingsHistoryContent: some View {
        VStack(spacing: 16) {
            if ratings.isEmpty {
                Text("No ratings yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(ratings) { rating in
                    RatingHistoryCard(rating: rating)
                }
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadHistory() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if currentUser == nil {
                    currentUser = try await SupabaseManager.shared.getCurrentUser()
                }
                
                // Load completed dates and ratings
                // Note: This would need to be implemented in SupabaseManager
                // For now, we'll use mock data
                await MainActor.run {
                    loadMockData()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load history: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Mock Data (for demonstration)
    private func loadMockData() {
        // Mock completed dates
        let mockDate1 = DateOption(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            time: Calendar.current.date(byAdding: .hour, value: 18, to: Date()) ?? Date(),
            location: "Kennedy School",
            venueName: "Kennedy School Hot Tub",
            address: "5736 NE 33rd Ave, Portland, OR 97211",
            latitude: 45.5511,
            longitude: -122.6214
        )
        
        let mockDate2 = DateOption(
            date: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            time: Calendar.current.date(byAdding: .hour, value: 19, to: Date()) ?? Date(),
            location: "Powell's Books",
            venueName: "Powell's City of Books",
            address: "1005 W Burnside St, Portland, OR 97209",
            latitude: 45.5231,
            longitude: -122.6814
        )
        
        let mockProposal1 = DateProposal(
            id: "1",
            matchId: "match1",
            proposerId: "user1",
            date1: mockDate1,
            date2: mockDate1,
            date3: mockDate1,
            selectedDateIndex: 0,
            status: .confirmed,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let mockProposal2 = DateProposal(
            id: "2",
            matchId: "match2",
            proposerId: "user2",
            date1: mockDate2,
            date2: mockDate2,
            date3: mockDate2,
            selectedDateIndex: 0,
            status: .confirmed,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        completedDates = [mockProposal1, mockProposal2]
        
        // Mock ratings
        let mockRating1 = Rating(
            id: "1",
            dateId: "1",
            raterId: "user1",
            ratedId: "user2",
            wouldMeetAgain: true,
            createdAt: Date()
        )
        
        let mockRating2 = Rating(
            id: "2",
            dateId: "2",
            raterId: "user2",
            ratedId: "user1",
            wouldMeetAgain: false,
            createdAt: Date()
        )
        
        ratings = [mockRating1, mockRating2]
    }
}

// MARK: - Date History Card
struct DateHistoryCard: View {
    let date: DateProposal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completed Date")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let selectedIndex = date.selectedDateIndex {
                        let selectedDate = [date.date1, date.date2, date.date3][selectedIndex]
                        Text(selectedDate.displayText)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(date.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Date completed successfully")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Rating History Card
struct RatingHistoryCard: View {
    let rating: Rating
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date Rating")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("You rated a date")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(rating.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: rating.wouldMeetAgain ? "heart.fill" : "xmark.circle.fill")
                    .foregroundColor(rating.wouldMeetAgain ? .green : .red)
                
                Text(rating.wouldMeetAgain ? "Would meet again" : "Not interested")
                    .font(.caption)
                    .foregroundColor(rating.wouldMeetAgain ? .green : .red)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
} 