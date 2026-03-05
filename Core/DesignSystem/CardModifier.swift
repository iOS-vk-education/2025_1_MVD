//
//  CardModifier.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/21/25.
//

import SwiftUI

struct CardModifier: ViewModifier {
    let appearance: CardAppearance
    func body(content: Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(appearance.borderWidth > 0 ? appearance.borderColor : appearance.backgroundColor)
                .brightness(-0.1)
                .offset(x: 0, y: 5)
            RoundedRectangle(cornerRadius: 12)
                .fill(appearance.backgroundColor)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(appearance.borderColor, lineWidth: appearance.borderWidth))
            content
                .padding(16)
                .foregroundColor(appearance.foregroundColor)
        }
    }
}

extension View {
    func cardStyle(_ appearance: CardAppearance) -> some View {
        self.modifier(CardModifier(appearance: appearance))
    }
}

