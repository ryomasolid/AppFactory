import Foundation

/// 支払い方法。**解約する場所は支払い方法で決まる**ので、サービスごとではなくここに一般的な手順を持つ。
///
/// サービス固有の URL は持たない（リンク切れの保守をしない）。
enum PaymentMethod: String, CaseIterable, Identifiable, Sendable {
    case creditCard
    case debit
    case appStore
    case googlePlay
    case carrier
    case amazon
    case paypay
    case paypal
    case bank
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .creditCard: String(localized: "クレジットカード")
        case .debit: String(localized: "デビットカード")
        case .appStore: String(localized: "App Store")
        case .googlePlay: String(localized: "Google Play")
        case .carrier: String(localized: "キャリア決済")
        case .amazon: String(localized: "Amazon")
        case .paypay: String(localized: "PayPay")
        case .paypal: String(localized: "PayPal")
        case .bank: String(localized: "口座振替")
        case .other: String(localized: "その他")
        }
    }

    /// 解約の一般的な手順（編集画面の初期値）。
    var cancelGuide: String {
        switch self {
        case .appStore:
            String(localized: "iPhone の「設定」→ いちばん上の自分の名前 →「サブスクリプション」から解約します。")
        case .googlePlay:
            String(localized: "Google Play ストアのアプリでプロフィールアイコン →「お支払いと定期購入」→「定期購入」から解約します。")
        case .carrier:
            String(localized: "契約している携帯電話会社の会員ページ（My docomo・My au・My SoftBank など）から解約します。")
        case .amazon:
            String(localized: "Amazon の「アカウントサービス」→「メンバーシップおよび購読」から解約します。")
        case .paypal:
            String(localized: "サービスの公式サイトやアプリで解約します。PayPal の「自動支払い」の設定からも停止できます。")
        case .creditCard, .debit, .paypay, .bank, .other:
            String(localized: "サービスの公式サイトやアプリの「アカウント」「会員情報」から解約します。カード会社などの支払い側では止められないことが多いので、サービス側で手続きしてください。")
        }
    }
}
