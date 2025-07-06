import SwiftUI

struct MainTabView: View {
    @Binding var isLoggedIn: Bool
    @Binding var firstName: String
    @Binding var userStatus: String
    @State private var selectedTab: Tab = .meetups

    var body: some View {
        TabView(selection: $selectedTab) {
            HistoryView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("History")
                }
                .tag(Tab.history)

            BlackBookView()
                .tabItem {
                    Image(systemName: "book")
                    Text("Black Book")
                }
                .tag(Tab.blackBook)

            DashboardView(
                isLoggedIn: $isLoggedIn,
                firstName: $firstName,
                userStatus: $userStatus
            )
            .tabItem {
                Image(systemName: "calendar")
                Text("Meetups")
            }
            .tag(Tab.meetups)

            MessagesView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Messages")
                }
                .tag(Tab.messages)

            AccountView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Account")
                }
                .tag(Tab.account)
        }
        .onAppear {
            // Ensure we start with the meetups tab
            selectedTab = .meetups
        }
    }
}

enum Tab: Int, CaseIterable {
    case history = 0
    case blackBook = 1
    case meetups = 2
    case messages = 3
    case account = 4
}

struct PlaceholderView: View {
    var title: String

    var body: some View {
        VStack {
            Spacer()
            Text("\(title) Screen")
                .font(.title)
                .foregroundColor(.gray)
            Spacer()
        }
    }
}
