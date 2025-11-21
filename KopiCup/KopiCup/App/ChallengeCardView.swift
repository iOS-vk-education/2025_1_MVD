import SwiftUI

struct ChallengeCardView: View {
    let challengeName: String
    let difficulty: Int
    @State private var isAccepted = false
    @State private var isCompleted = false
    @State private var isHidden = false
    
    var body: some View {
        if !isHidden {
            CardView(
                cardName: "Карточка челленджа",
                mainText: isAccepted ? challengeName : "Челлендж недели",
                subtitle: isAccepted ? "Отмечай свои успехи!" : challengeName,
                
                content: {
                    if isAccepted {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        isCompleted.toggle()
                                    }
                                withAnimation(.easeInOut(duration: 0.8).delay(0.7)) {
                                        isHidden = true
                                    }
                            }) {
                                HStack  {
                                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.largeTitle)
                                        .foregroundColor(isCompleted ? .green : .white)
                                    
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } else {
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            Button("Принять") {
                                withAnimation {
                                    isAccepted = true
                                }
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                            
                            Button("Откажусь") {
                                withAnimation {
                                    isHidden = true
                                }
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                },
                imageContent: {
                    VStack(spacing: 4) {
                            ForEach(0..<difficulty, id: \.self) { _ in
                                Image(systemName: "bolt.fill")
                                    .font(.title)
                                    .foregroundColor(.orange)
                            }
                        }
                },
                
                backgroundColor: isAccepted ? .blue : .white,
                foregroundColor: isAccepted ? .white : .blue,
                borderColor: isAccepted ? .clear : .blue,
                hasBorder: !isAccepted
            )
        }
    }
}
