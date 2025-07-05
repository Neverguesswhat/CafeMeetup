import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://lhtudqxldzwloyyxgvrx.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxodHVkcXhsZHp3bG95eXhndnJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5MDU3NTcsImV4cCI6MjA2NTQ4MTc1N30.Qh34YH6mEn-2y2GB1TZ64xMFyn4bbEsS3nw2mDlOlro"
        )
    }
}
