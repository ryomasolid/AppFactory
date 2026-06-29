import Photos
import SwiftUI

public struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @AppStorage("pc.hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    @State private var store = StoreManager()

    private let service = PhotoLibraryService()

    public init() {}

    public var body: some View {
        Group {
            switch authStatus {
            case .authorized, .limited:
                CategoryHomeView()
                    .environment(store)
            default:
                NavigationStack {
                    PermissionView(status: authStatus) {
                        authStatus = await service.requestAuthorization()
                    }
                    .navigationTitle("PhotoCleaner")
                }
            }
        }
        .onAppear {
            showOnboarding = !hasSeenOnboarding
            authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            // 広告の同意（UMP）→ ATT → AdMob 初期化を実行。
            ConsentManager.shared.start()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // 設定アプリで権限を変更して戻ってきた場合に再評価する。
            if phase == .active {
                authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            }
        }
    }
}

#Preview {
    ContentView()
}
