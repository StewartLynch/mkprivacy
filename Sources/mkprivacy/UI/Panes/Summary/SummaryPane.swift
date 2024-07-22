import SwiftUI

struct SummaryPane: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        let assembledManifest = appModel.assembledPrivacyManifest()
        let summarizedCategories = appModel.summarizeDataCollectionCategories(assembledManifest)
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Summary")
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)

                warnings()
                privacyTracking(assembledManifest)
                trackingDomains(assembledManifest)
                dataCollection(assembledManifest, summarizedCategories)
            }
            .padding()
            .padding()
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
        .background(Color(NSColor.controlBackgroundColor))
    }

    @ViewBuilder private func warnings() -> some View {
        if appModel.warningTrackingButNoTrackingDatatypes {
            Warning("No collected data types have been marked for use with tracking yet.", goTo: .collectedDataTypes)
                .padding(.bottom, 16)
        }
        if appModel.warningNotTrackingButTrackingDataTypes {
            Warning("Some collected data types have been marked for use with tracking.", goTo: .collectedDataTypes)
                .padding(.bottom, 16)
        }
        if appModel.warningNotTrackingButTrackingDomains {
            Warning("Tracking domains have been added, without tracking enabled.", goTo: .trackingDomains)
                .padding(.bottom, 16)
        }
        if appModel.warningDataTypePurposeRequired {
            if appModel.warningDataTypePurposeRequiredCount > 1 {
                Warning("No collection purpose selected for \(appModel.warningDataTypePurposeRequiredCount) collected data types.", goTo: .collectedDataTypes)
                    .padding(.bottom, 16)
            } else {
                Warning("No collection purpose selected for a collected data type.", goTo: .collectedDataTypes)
                    .padding(.bottom, 16)
            }
        }

    }

    @ViewBuilder private func privacyTracking(_ privacyManifest: PrivacyManifest) -> some View {
        VStack {
            if privacyManifest.privacyTracking {
                HStack {
                    Image(systemName: "person.fill.viewfinder")
                        .imageScale(.large)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentColor)
                    Text("The app or 3rd-party SDK indicates that it does use data for tracking.")
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .imageScale(.large)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentColor)
                    Text("The app or 3rd-party SDK indicates that it **does not** use data for tracking.")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 40)
        .background(.quinary)
        .clipShape(RoundedRectangle(cornerSize: .init(width: 12, height: 12), style: .continuous))
        .padding(.bottom, 16)
    }

    @ViewBuilder private func trackingDomains(_ privacyManifest: PrivacyManifest) -> some View {
        let count = privacyManifest.trackingDomains.count
        if count > 0 {
            VStack {
                HStack {
                    Image(systemName: "network.badge.shield.half.filled")
                        .imageScale(.large)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentColor)
                    if count == 1 {
                        Text("There is an Internet domain engaged in tracking.")
                    } else {
                        Text("There are \(String(privacyManifest.trackingDomains.count)) Internet domains engaged in tracking.")
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
            .background(.quinary)
            .clipShape(RoundedRectangle(cornerSize: .init(width: 12, height: 12), style: .continuous))
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder private func dataCollection(
        _ privacyManifest: PrivacyManifest,
        _ summarizedCategories: SummarizedCategories
    ) -> some View {

        VStack(spacing: 16) {

            if !summarizedCategories.tracking.isEmpty {
                VStack(spacing: 0) {
                    Image(systemName: "person.fill.viewfinder")
                        .foregroundStyle(Color.accentColor)
                        .imageScale(.large)
                        .font(.title)
                        .fontWeight(.medium)
                        .padding(.bottom, 6)
                    Text("Data Used to track You")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    Text("The following data may be used to track you across apps\nand websites owned by other companies:")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 12)
                    LazyVGrid(columns: columns(itemCount: summarizedCategories.tracking.count)) {
                        ForEach(summarizedCategories.tracking) { category in
                            HStack(spacing: 6) {
                                VStack {
                                    Image(systemName: category.icon)
                                }.frame(width: 20)
                                Text(category.description)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 40)
                .background(.quinary)
                .clipShape(RoundedRectangle(cornerSize: .init(width: 12, height: 12), style: .continuous))
            }

            if !summarizedCategories.linked.isEmpty {
                VStack(spacing: 0) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Color.accentColor)
                        .imageScale(.large)
                        .font(.title)
                        .fontWeight(.medium)
                        .padding(.bottom, 6)
                    Text("Data Linked to You")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    Text("The following data may be collected and linked to your identity:")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 12)
                    LazyVGrid(columns: columns(itemCount: summarizedCategories.linked.count)) {
                        ForEach(summarizedCategories.linked) { category in
                            HStack(spacing: 6) {
                                VStack {
                                    Image(systemName: category.icon)
                                }.frame(width: 20)
                                Text(category.description)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 40)
                .background(.quinary)
                .clipShape(RoundedRectangle(cornerSize: .init(width: 12, height: 12), style: .continuous))
            }

            if !summarizedCategories.notLinked.isEmpty {
                VStack(spacing: 0) {
                    Image(systemName: "person.slash.fill")
                        .foregroundStyle(Color.accentColor)
                        .imageScale(.large)
                        .font(.title)
                        .fontWeight(.medium)
                        .padding(.bottom, 6)
                    Text("Data Not Linked to You")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    Text("The following may be collected but is not linked to your identity:")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 12)
                    LazyVGrid(columns: columns(itemCount: summarizedCategories.notLinked.count)) {
                        ForEach(summarizedCategories.notLinked) { category in
                            HStack(spacing: 6) {
                                VStack {
                                    Image(systemName: category.icon)
                                }.frame(width: 20)
                                Text(category.description)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 40)
                .background(.quinary)
                .clipShape(RoundedRectangle(cornerSize: .init(width: 12, height: 12), style: .continuous))
            }
        }
    }

    private func columns(itemCount: Int) -> [GridItem] {
        switch itemCount {
        case 1: [GridItem(alignment: .center)]
        case 2: [GridItem(alignment: .center), GridItem(alignment: .center)]
        default: [GridItem(alignment: .leading), GridItem(alignment: .leading), GridItem(alignment: .leading)]
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    SummaryPane()
        .environment(AppModel())
}
#endif
