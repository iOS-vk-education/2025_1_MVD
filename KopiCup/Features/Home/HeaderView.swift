//
//  HeaderView.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

struct HeaderView: View {
    let name: String
    @EnvironmentObject private var l10n: L10n

    var body: some View {
        Text(l10n.t(.keepGoing))
            .font(.title3)
            .padding(.horizontal)
    }
}
