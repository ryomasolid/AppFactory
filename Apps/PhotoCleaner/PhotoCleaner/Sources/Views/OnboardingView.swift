import SwiftUI

/// 初回起動時の説明画面。何ができるアプリかを3点で伝える。
struct OnboardingView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("PhotoCleaner")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 20) {
                feature("rectangle.stack", "重複・類似を自動検出", "似た写真をグループにまとめて表示します")
                feature("checkmark.circle", "まとめて整理", "残す1枚を選び、ほかを一括で削除")
                feature("lock.shield", "完全オンデバイス", "写真が外部に送信されることはありません")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onDone) {
                Text("はじめる")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding()
        }
    }

    private func feature(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
