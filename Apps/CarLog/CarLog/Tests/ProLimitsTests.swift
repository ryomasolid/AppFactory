import Foundation
import Testing
@testable import CarLog

/// 無料版の上限。課金の線引きそのものなので、境界をテストで固定する。
struct ProLimitsTests {

    @Test func freeUserCanRegisterOneVehicle() {
        #expect(ProLimits.canAddVehicle(currentCount: 0, isPro: false))
        #expect(!ProLimits.canAddVehicle(currentCount: 1, isPro: false))
        #expect(ProLimits.canAddVehicle(currentCount: 5, isPro: true))
    }

    @Test func freeUserCanAddUpToThreeMaintenanceItems() {
        #expect(ProLimits.canAddMaintenanceItem(currentCount: 2, isPro: false))
        #expect(!ProLimits.canAddMaintenanceItem(currentCount: 3, isPro: false))
        #expect(ProLimits.canAddMaintenanceItem(currentCount: 100, isPro: true))
    }

    @Test func remainingCountsDownToZeroAndNeverNegative() {
        #expect(ProLimits.remainingMaintenanceItems(currentCount: 0, isPro: false) == 3)
        #expect(ProLimits.remainingMaintenanceItems(currentCount: 3, isPro: false) == 0)
        // デモデータのように上限を超えて持っていても、負の数を出さない。
        #expect(ProLimits.remainingMaintenanceItems(currentCount: 8, isPro: false) == 0)
        #expect(ProLimits.remainingMaintenanceItems(currentCount: 8, isPro: true) == nil)
    }

    @Test func recordsAndCalculationsAreNeverLimited() {
        // 記録件数に上限を置かない設計を固定する。
        #expect(ProLimits.freeRecordLimit == nil)
    }

    @Test func recommendedTemplatesFitTheFreeLimit() {
        // オンボーディングの既定チェック（オイル・車検・税）が無料枠にちょうど収まること。
        #expect(MaintenanceTemplate.all.filter(\.isRecommended).count == ProLimits.freeMaintenanceItems)
    }

    @Test func csvExportIsPro() {
        #expect(!ProLimits.canExportCSV(isPro: false))
        #expect(ProLimits.canExportCSV(isPro: true))
    }
}
