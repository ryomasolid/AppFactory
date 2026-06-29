import Photos
import SwiftUI

public struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @AppStorage("pc.hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    private let service = PhotoLibraryService()

    public init() {}

    public var body: some View {
        Group {
            switch authStatus {
            case .authorized, .limited:
                CategoryHomeView()
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
