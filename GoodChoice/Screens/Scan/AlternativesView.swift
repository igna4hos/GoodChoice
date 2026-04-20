import SwiftUI

struct AlternativesView: View {
    @EnvironmentObject private var store: AppStore

    let alternatives: [EvaluatedAlternative]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(alternatives) { alternative in
                        AlternativeRowView(alternative: alternative)
                            .environmentObject(store)
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(Text("scan.alternatives.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
