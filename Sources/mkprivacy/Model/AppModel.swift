import Foundation
import AppKit
import SwiftUI

@Observable class AppModel {

    var selectedSidebarItem: SidebarItem?
    var selectedRequiredReasonsAPI: String?
    var selectedCollectionCategory: CollectionCategory?

    var hoveredPurpose: CollectionPurposes?
    var hoveredPurposeDataType: String?

    var windowIsAlwaysOnTop: Bool = false

    var isShowingError: Bool = false
    var error: Error?

    var isWarningActive: Bool {
        warningTrackingButNoTrackingDatatypes
        || warningNotTrackingButTrackingDataTypes
        || warningNotTrackingButTrackingDomains
        || warningDataTypePurposeRequired
    }

    var warningTrackingButNoTrackingDatatypes: Bool = false
    var warningNotTrackingButTrackingDataTypes: Bool = false
    var warningNotTrackingButTrackingDomains: Bool = false
    var warningDataTypePurposeRequired: Bool = false
    var warningDataTypePurposeRequiredCount: Int = 0

    var privacyManifest = PrivacyManifest() {
        didSet {
            validate()
        }
    }

    var dataTypes: [String: CollectedDataType] {
        didSet {
            assemblePrivacyManifest()
        }
    }

    var apiReasons: [String: [String]] {
        didSet {
            assemblePrivacyManifest()
        }
    }

    init() {
        dataTypes = [:]
        apiReasons = [:]
    }

    func validate() {
        warningTrackingButNoTrackingDatatypes = false
        warningNotTrackingButTrackingDataTypes = false
        warningNotTrackingButTrackingDomains = false
        warningDataTypePurposeRequired = false
        warningDataTypePurposeRequiredCount = 0

        if privacyManifest.privacyTracking, dataTypes.filter({ $0.value.isTracking }).isEmpty {
            warningTrackingButNoTrackingDatatypes = true
        } else if !privacyManifest.privacyTracking, !dataTypes.filter({ $0.value.isTracking }).isEmpty {
            warningNotTrackingButTrackingDataTypes = true
        }

        if !privacyManifest.privacyTracking, !privacyManifest.trackingDomains.isEmpty {
            warningNotTrackingButTrackingDomains = true
        }

        for (_, dataType) in dataTypes {
            if dataType.purposes.isEmpty {
                warningDataTypePurposeRequired = true
                warningDataTypePurposeRequiredCount += 1
            }
        }
    }

    func clearPrivacyManifest() {
        selectedSidebarItem = nil
        Task { @MainActor in
            // If we don't sleep here, the app will crash if e.g. a tracking
            // domain text field has focus. SwiftUI. 😐
            try? await Task.sleep(for: .milliseconds(200))
            privacyManifest = PrivacyManifest()
            dataTypes = [:]
            apiReasons = [:]
        }
    }

    func importPrivacyManifest(_ manifest: PrivacyManifest) {
        selectedSidebarItem = nil
        Task { @MainActor in
            // If we don't sleep here, the app will crash if e.g. a tracking
            // domain text field has focus. SwiftUI. 😐
            try? await Task.sleep(for: .milliseconds(200))
            
            var dataTypes: [String: CollectedDataType] = [:]
            for dataType in manifest.collectedDataTypes {
                dataTypes[dataType.type] = dataType
            }

            var apiReasons: [String: [String]] = [:]
            for apiType in manifest.accessedAPITypes {
                apiReasons[apiType.type] = apiType.reasons
            }

            privacyManifest = manifest
            self.dataTypes = dataTypes
            self.apiReasons = apiReasons

            selectedSidebarItem = .summary
        }
    }

    private func assemblePrivacyManifest() {
        privacyManifest = PrivacyManifest(
            privacyTracking: privacyManifest.privacyTracking,
            trackingDomains: privacyManifest.trackingDomains,
            collectedDataTypes: Array(dataTypes.values),
            accessedAPITypes: apiReasons.map { (type, reasons) in
                AccessedAPIType(type: type, reasons: reasons)
            }
        )
    }

    func manifestAsPlistText() -> String {
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(privacyManifest)
            let string = String(data: data, encoding: .utf8)
            return string ?? "Failed to encode property list."
        } catch {
            return error.localizedDescription
        }
    }

    func copyPrivacyManifestToPasteboard() {
        let string = manifestAsPlistText()
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(string, forType: .string)
    }

    func makeDocument() -> PrivacyManifestDocument {
        return PrivacyManifestDocument(privacyManifest)
    }

    func showError(_ error: Swift.Error) {
        self.error = error
        self.isShowingError = true
    }

    var summarizeRequiredReasonsAPIs: [(name: String, icon: String)] {
        return privacyManifest.accessedAPITypes.compactMap {
            switch $0.type {
            case ActiveKeyboardAPIs.key: return (name: ActiveKeyboardAPIs.name, icon: ActiveKeyboardAPIs.icon)
            case DiskSpaceAPIs.key: return (name: DiskSpaceAPIs.name, icon: DiskSpaceAPIs.icon)
            case FileTimestampAPIs.key: return (name: FileTimestampAPIs.name, icon: FileTimestampAPIs.icon)
            case SystemBootTimeAPIs.key: return (name: SystemBootTimeAPIs.name, icon: SystemBootTimeAPIs.icon)
            case UserDefaultsAPIs.key: return (name: UserDefaultsAPIs.name, icon: UserDefaultsAPIs.icon)
            default:
                return nil
            }
        }.sorted { a, b in
            a.name < b.name
        }
    }

    var summarizeDataCollectionCategories: SummarizedCategories {
        var tracking = Set<CollectionCategory>()
        var linked = Set<CollectionCategory>()
        var notLinked = Set<CollectionCategory>()

        func insertCategory(_ category: CollectionCategory, for dataType: CollectedDataType) {
            if dataType.isTracking {
                tracking.insert(category)
            }
            if dataType.isLinked {
                linked.insert(category)
            } else {
                notLinked.insert(category)
            }
        }

        for dataType in privacyManifest.collectedDataTypes {
            if BodyCategory.contains(dataType) { insertCategory(.body, for: dataType) }
            if BrowsingHistoryCategory.contains(dataType) { insertCategory(.browsingHistory, for: dataType) }
            if ContactInfoCategory.contains(dataType) { insertCategory(.contactInfo, for: dataType) }
            if ContactsInfoCategory.contains(dataType) { insertCategory(.contactsInfo, for: dataType) }
            if DiagnosticsCategory.contains(dataType) { insertCategory(.diagnostics, for: dataType) }
            if FinancialInfoCategory.contains(dataType) { insertCategory(.financialInfo, for: dataType) }
            if HealthAndFitnessCategory.contains(dataType) { insertCategory(.healthAndFitness, for: dataType) }
            if IdentifiersCategory.contains(dataType) { insertCategory(.identifiers, for: dataType) }
            if LocationInfoCategory.contains(dataType) { insertCategory(.locationInfo, for: dataType) }
            if OtherDataTypesCategory.contains(dataType) { insertCategory(.otherDataTypes, for: dataType) }
            if PurchasesCategory.contains(dataType) { insertCategory(.purchases, for: dataType) }
            if SearchHistoryCategory.contains(dataType) { insertCategory(.searchHistory, for: dataType) }
            if SensitiveInfoCategory.contains(dataType) { insertCategory(.sensitiveInfo, for: dataType) }
            if SurroundingsCategory.contains(dataType) { insertCategory(.surroundings, for: dataType) }
            if UsageDataCategory.contains(dataType) { insertCategory(.usageData, for: dataType) }
            if UserContentCategory.contains(dataType) { insertCategory(.userContent, for: dataType) }
        }

        return (
            tracking: Array(tracking).sorted(by: { a, b in a.description < b.description }),
            linked: Array(linked).sorted(by: { a, b in a.description < b.description }),
            notLinked: Array(notLinked).sorted(by: { a, b in a.description < b.description })
        )
    }
}

typealias SummarizedCategories = (
    tracking: [CollectionCategory],
    linked: [CollectionCategory],
    notLinked: [CollectionCategory]
)

fileprivate extension CollectedCategory {
    static func contains(_ type: CollectedDataType) -> Bool {
        Self.allCases.map(\.id).contains(type.type)
    }
}
