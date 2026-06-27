import Photos
import SwiftUI

/// 認可が未決定・拒否・制限のときに表示する案内画面。
struct PermissionView: View {
    let status: PHAuthorizationStatus
    let onRequest: () async -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("写真ライブラリへのアクセス")
                .font(.title2.bold())

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            actionButton
        }
        .padding()
    }

    private var message: String {
        switch status {
        case .notDetermined:
            return "重複・類似した写真を端末内だけで検出します。写真が外部に送信されることはありません。"
        case .denied, .restricted:
            return "アクセスが許可されていません。設定アプリから写真へのアクセスを許可してください。"
        case .limited:
            return "選択された写真のみにアクセスできます。すべての写真を対象にするには設定で変更してください。"
        case .authorized:
            return ""
        @unknown default:
            return ""
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch status {
        case .notDetermined:
            Button("写真へのアクセスを許可") {
                Task { await onRequest() }
            }
            .buttonStyle(.borderedProminent)
        case .denied, .restricted, .limited:
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        case .authorized:
            EmptyView()
        @unknown default:
            EmptyView()
        }
    }
}
