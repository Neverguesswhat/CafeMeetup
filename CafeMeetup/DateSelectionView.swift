import SwiftUI
import MapKit

struct DateSelectionView: View {
    let matchId: String
    let proposerId: String
    let onDateProposalCreated: (DateProposal) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var date1 = DateOption(
        date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
        time: Calendar.current.date(byAdding: .hour, value: 18, to: Date()) ?? Date(),
        location: "Kennedy School",
        venueName: "Kennedy School Hot Tub",
        address: "5736 NE 33rd Ave, Portland, OR 97211",
        latitude: 45.5511,
        longitude: -122.6214
    )
    
    @State private var date2 = DateOption(
        date: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
        time: Calendar.current.date(byAdding: .hour, value: 19, to: Date()) ?? Date(),
        location: "Zach's Shack",
        venueName: "Zach's Shack",
        address: "1234 SE Division St, Portland, OR 97202",
        latitude: 45.5046,
        longitude: -122.6314
    )
    
    @State private var date3 = DateOption(
        date: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
        time: Calendar.current.date(byAdding: .hour, value: 20, to: Date()) ?? Date(),
        location: "Powell's Books",
        venueName: "Powell's City of Books",
        address: "1005 W Burnside St, Portland, OR 97209",
        latitude: 45.5231,
        longitude: -122.6814
    )
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var selectedVenueIndex = 0
    
    private let venueOptions = [
        ("Kennedy School Hot Tub", "5736 NE 33rd Ave, Portland, OR 97211", 45.5511, -122.6214),
        ("Zach's Shack", "1234 SE Division St, Portland, OR 97202", 45.5046, -122.6314),
        ("Powell's Books", "1005 W Burnside St, Portland, OR 97209", 45.5231, -122.6814),
        ("McMenamins Edgefield", "2126 SW Halsey St, Troutdale, OR 97060", 45.5401, -122.3874),
        ("The Grotto", "8840 NE Skidmore St, Portland, OR 97220", 45.5511, -122.5214),
        ("Forest Park", "NW 29th Ave & Upshur St, Portland, OR 97210", 45.5511, -122.7214),
        ("Portland Japanese Garden", "611 SW Kingston Ave, Portland, OR 97205", 45.5191, -122.7014),
        ("Oaks Amusement Park", "7805 SE Oaks Park Way, Portland, OR 97202", 45.4641, -122.6514),
        ("Crystal Springs Rhododendron Garden", "5801 SE 28th Ave, Portland, OR 97202", 45.4841, -122.6414),
        ("Portland Art Museum", "1219 SW Park Ave, Portland, OR 97205", 45.5191, -122.6814)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Select 3 Date Options")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Choose 3 different dates and venues for your match to pick from. Dates must be within the next 3 days.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Date 1
                    DateOptionCard(
                        title: "Date Option 1",
                        dateOption: $date1,
                        venueOptions: venueOptions,
                        selectedVenueIndex: $selectedVenueIndex
                    )
                    
                    // Date 2
                    DateOptionCard(
                        title: "Date Option 2",
                        dateOption: $date2,
                        venueOptions: venueOptions,
                        selectedVenueIndex: $selectedVenueIndex
                    )
                    
                    // Date 3
                    DateOptionCard(
                        title: "Date Option 3",
                        dateOption: $date3,
                        venueOptions: venueOptions,
                        selectedVenueIndex: $selectedVenueIndex
                    )
                    
                    // Submit Button
                    Button(action: submitDateProposal) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text("Submit Date Options")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || !isValidProposal)
                    
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
            .navigationTitle("Date Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isValidProposal: Bool {
        // Check that all dates are within 3 days
        let calendar = Calendar.current
        let now = Date()
        
        let date1Valid = calendar.dateComponents([.day], from: now, to: date1.fullDateTime).day ?? 0 <= 3
        let date2Valid = calendar.dateComponents([.day], from: now, to: date2.fullDateTime).day ?? 0 <= 3
        let date3Valid = calendar.dateComponents([.day], from: now, to: date3.fullDateTime).day ?? 0 <= 3
        
        // Check that dates are different
        let datesAreDifferent = date1.fullDateTime != date2.fullDateTime && 
                               date2.fullDateTime != date3.fullDateTime && 
                               date1.fullDateTime != date3.fullDateTime
        
        return date1Valid && date2Valid && date3Valid && datesAreDifferent
    }
    
    private func submitDateProposal() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let proposal = try await SupabaseManager.shared.createDateProposal(
                    matchId: matchId,
                    proposerId: proposerId,
                    date1: date1,
                    date2: date2,
                    date3: date3
                )
                
                await MainActor.run {
                    onDateProposalCreated(proposal)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to submit date proposal: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct DateOptionCard: View {
    let title: String
    @Binding var dateOption: DateOption
    let venueOptions: [(String, String, Double, Double)]
    @Binding var selectedVenueIndex: Int
    
    @State private var showingVenuePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            // Date and Time Selection
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    DatePicker("", selection: $dateOption.date, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    DatePicker("", selection: $dateOption.time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                }
            }
            
            // Venue Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Venue")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Button(action: {
                    showingVenuePicker = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dateOption.venueName)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text(dateOption.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
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
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingVenuePicker) {
            VenuePickerView(
                venueOptions: venueOptions,
                selectedVenueIndex: $selectedVenueIndex,
                onVenueSelected: { index in
                    let venue = venueOptions[index]
                    dateOption.venueName = venue.0
                    dateOption.address = venue.1
                    dateOption.latitude = venue.2
                    dateOption.longitude = venue.3
                    showingVenuePicker = false
                }
            )
        }
    }
}

struct VenuePickerView: View {
    let venueOptions: [(String, String, Double, Double)]
    @Binding var selectedVenueIndex: Int
    let onVenueSelected: (Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(venueOptions.enumerated()), id: \.offset) { index, venue in
                    Button(action: {
                        onVenueSelected(index)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(venue.0)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(venue.1)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Venue")
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