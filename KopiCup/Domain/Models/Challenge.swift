//
//  Challenge.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

struct Challenge: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let nameEn: String?
    let descriptionEn: String?
    let difficulty: Int

    init(
        id: String,
        name: String,
        description: String,
        nameEn: String? = nil,
        descriptionEn: String? = nil,
        difficulty: Int
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.nameEn = nameEn
        self.descriptionEn = descriptionEn
        self.difficulty = difficulty
    }

    func localizedName(for language: AppLanguage = L10n.shared.language) -> String {
        localizedValue(primary: name, english: nameEn, language: language)
    }

    func localizedDescription(for language: AppLanguage = L10n.shared.language) -> String {
        localizedValue(primary: description, english: descriptionEn, language: language)
    }

    private func localizedValue(primary: String, english: String?, language: AppLanguage) -> String {
        switch language {
        case .ru:
            return primary
        case .en:
            let trimmed = english?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? primary : trimmed
        }
    }
}
