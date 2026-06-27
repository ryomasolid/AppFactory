import Photos
import SwiftUI

public struct ContentView: View {
    @State private var viewModel = PhotoLibraryViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("PhotoCleaner")
        }
        .task {
            await viewModel.loadIfAuthorized()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.authorizationStatus {
        case .authorized, .limited:
            authorizedContent
        default:
            PermissionView(status: viewModel.authorizationStatus) {
                await viewModel.requestAccessAndLoad()
            }
        }
    }

    @ViewBuilder
    private var authorizedContent: some View {
        switch viewModel.phase {
        case .idle, .loading:
            ProgressView("写真を読み込み中…")
        case .scanning(let progress):
            VStack(spacing: 12) {
                ProgressView(value: progress)
                    .frame(maxWidth: 240)
                Text("類似写真を解析中… \(Int(progress * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        case .ready:
            if viewModel.groups.isEmpty {
                ContentUnavailableView(
                    "類似写真は見つかりませんでした",
                    systemImage: "checkmark.circle",
                    description: Text("\(viewModel.assetCount) 枚をスキャンしました")
                )
            } else {
                SimilarityGridView(groups: viewModel.groups, service: viewModel.service)
            }
        }
    }
}

#Preview {
    ContentView()
}
