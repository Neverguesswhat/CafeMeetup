import SwiftUI
import MapKit

struct AttendanceConfirmationView: View {
    let dateProposal: DateProposal
    let onAttendanceConfirmed: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var confirmationCode = ""
    @State private var showCodeEntry = false
    @State private var showQRScanner = false
    @State private var attendanceRecord: Attendance?
    @State private var currentUser: User?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Confirm Attendance")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Confirm that you'll attend your scheduled date and verify you actually met.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Date Details
                    dateDetailsSection
                    
                    // Attendance Confirmation
                    attendanceConfirmationSection
                    
                    // Code Entry (if needed)
                    if showCodeEntry {
                        codeEntrySection
                    }
                    
                    // QR Code Scanner
                    if showQRScanner {
                        qrScannerSection
                    }
                    
                    // Error display
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
            .navigationTitle("Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentUser()
                createAttendanceRecord()
            }
        }
    }
    
    // MARK: - Date Details Section
    private var dateDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date Details")
                .font(.headline)
            
            if let selectedIndex = dateProposal.selectedDateIndex {
                let selectedDate = [dateProposal.date1, dateProposal.date2, dateProposal.date3][selectedIndex]
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(selectedDate.displayText)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.green)
                        Text(selectedDate.address)
                            .font(.body)
                    }
                    
                    if let latitude = selectedDate.latitude, let longitude = selectedDate.longitude {
                        Map(coordinateRegion: .constant(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )))
                        .frame(height: 200)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Attendance Confirmation Section
    private var attendanceConfirmationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confirm Attendance")
                .font(.headline)
            
            VStack(spacing: 16) {
                Button(action: confirmAttendance) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("I Confirm I'll Be There")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                
                Text("After confirming, you'll need to verify you actually met by entering a 4-digit code or scanning a QR code.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Code Entry Section
    private var codeEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verify Meeting")
                .font(.headline)
            
            VStack(spacing: 16) {
                Text("Enter the 4-digit code from your date partner to verify you actually met:")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        TextField("", text: Binding(
                            get: {
                                if index < confirmationCode.count {
                                    return String(confirmationCode[confirmationCode.index(confirmationCode.startIndex, offsetBy: index)])
                                }
                                return ""
                            },
                            set: { newValue in
                                if newValue.count <= 1 {
                                    if newValue.isEmpty {
                                        if confirmationCode.count > index {
                                            confirmationCode.remove(at: confirmationCode.index(confirmationCode.startIndex, offsetBy: index))
                                        }
                                    } else {
                                        if index < confirmationCode.count {
                                            confirmationCode.remove(at: confirmationCode.index(confirmationCode.startIndex, offsetBy: index))
                                            confirmationCode.insert(newValue.first!, at: confirmationCode.index(confirmationCode.startIndex, offsetBy: index))
                                        } else {
                                            confirmationCode.append(newValue.first!)
                                        }
                                    }
                                }
                            }
                        ))
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60, height: 60)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .fontWeight(.bold)
                    }
                }
                
                Button(action: verifyCode) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Verify Code")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading || confirmationCode.count != 4)
                
                Button("Scan QR Code Instead") {
                    showCodeEntry = false
                    showQRScanner = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - QR Scanner Section
    private var qrScannerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scan QR Code")
                .font(.headline)
            
            VStack(spacing: 16) {
                Text("Scan your date partner's QR code to verify you actually met:")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                // Placeholder for QR scanner
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .overlay(
                        VStack {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("QR Scanner")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    )
                    .cornerRadius(12)
                
                Button("Enter Code Instead") {
                    showQRScanner = false
                    showCodeEntry = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private func loadCurrentUser() {
        Task {
            do {
                currentUser = try await SupabaseManager.shared.getCurrentUser()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load user: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func createAttendanceRecord() {
        Task {
            do {
                guard let user = currentUser else { return }
                
                attendanceRecord = try await SupabaseManager.shared.createAttendanceRecord(
                    dateId: dateProposal.id,
                    userId: user.id
                )
                
                await MainActor.run {
                    if let record = attendanceRecord {
                        print("Confirmation code: \(record.confirmationCode ?? "No code")")
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create attendance record: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func confirmAttendance() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                guard let record = attendanceRecord else {
                    await MainActor.run {
                        errorMessage = "No attendance record found"
                        isLoading = false
                    }
                    return
                }
                
                try await SupabaseManager.shared.confirmAttendance(attendanceId: record.id)
                
                await MainActor.run {
                    isLoading = false
                    showCodeEntry = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to confirm attendance: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func verifyCode() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let isValid = try await SupabaseManager.shared.verifyConfirmationCode(
                    dateId: dateProposal.id,
                    code: confirmationCode
                )
                
                await MainActor.run {
                    isLoading = false
                    
                    if isValid {
                        // Send success message
                        if let user = currentUser {
                            Task {
                                try await SupabaseManager.shared.createMessage(
                                    userId: user.id,
                                    title: "Meeting Verified!",
                                    body: "Great! You've successfully verified your meeting. Your date partner has also confirmed attendance.",
                                    type: .attendance
                                )
                            }
                        }
                        
                        onAttendanceConfirmed()
                    } else {
                        errorMessage = "Invalid confirmation code. Please try again."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to verify code: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - QR Code Generator
struct QRCodeGenerator {
    static func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            
            if let outputImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledImage = outputImage.transformed(by: transform)
                
                let context = CIContext()
                if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
} 