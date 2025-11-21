//
//  CardDetailsView.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 21.11.2025.
//

import SwiftUI

struct CardDetailsView: View {
    let cardName: String
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 20) {
            Spacer()
            
            Text("Детали")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Была открыта карточка:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(cardName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .navigationTitle(cardName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CardDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        CardDetailsView(cardName: "Карточка")
    }
}
