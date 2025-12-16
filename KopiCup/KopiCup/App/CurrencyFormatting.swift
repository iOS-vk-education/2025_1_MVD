import Foundation

extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Currency {
    static func rub(locale: Locale = Locale(identifier: "ru_RU")) -> Self {
        .currency(code: "RUB").locale(locale)
    }
}
