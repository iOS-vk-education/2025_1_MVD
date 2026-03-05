//
//  ChallengeDetailsView.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

struct ChallengeDetailView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ChallengeViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Челлендж").font(.title2).fontWeight(.bold)
                Spacer()
                Button(action: { isPresented = false }) { Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray) }
            }
            .padding()
            
            if let challenge = viewModel.displayedChallenge {
                VStack(spacing: 20) {
                    Text(challenge.name).font(.title3).fontWeight(.bold)
                    Text(challenge.description).multilineTextAlignment(.center).foregroundColor(.secondary)
                    
                    if let uc = viewModel.activeChallenge {
                        HStack {
                            ForEach(0..<7, id: \.self) { i in
                                Circle().fill(uc.progress[i] ? Color.green : Color.gray.opacity(0.3)).frame(width: 30)
                                    .overlay(Text("\(i+1)").font(.caption).foregroundColor(.white))
                            }
                        }
                        
                        Button(action: { viewModel.markToday(); isPresented = false }) {
                            Text("Отметиться сегодня").foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.blue).cornerRadius(12)
                        }
                        .disabled(!(!uc.isTodayCompleted))
                        
                        Button("Отказаться") { viewModel.declineActiveChallenge() }.foregroundColor(.red)
                    }
                }
                .padding()
            }
        }
    }
}

