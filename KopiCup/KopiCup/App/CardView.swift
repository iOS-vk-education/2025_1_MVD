import SwiftUI

struct CardView<Content: View, ImageContent: View>: View {
    let cardName: String
    let mainText: String
    let subtitle: String?
    let content: AnyView
    let imageContent: AnyView
    
    let backgroundColor: Color
    let foregroundColor: Color
    let borderColor: Color
    let hasBorder: Bool
    
    private var borderWidth: Double {
            hasBorder ? 3 : 0
        }
    
    private var shadowColor: Color {
        hasBorder ? borderColor : backgroundColor
    }
    
    init(
        cardName: String = "Карточка",
        mainText: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder imageContent: () -> ImageContent,
        
        backgroundColor: Color = Color(.systemBackground),
        foregroundColor: Color = .secondary,
        borderColor: Color = .clear,
        hasBorder: Bool = false
    ) {
        self.cardName = cardName
        self.mainText = mainText
        self.subtitle = subtitle
        self.content = AnyView(content())
        self.imageContent = AnyView(imageContent())
        
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.borderColor = borderColor
        self.hasBorder = hasBorder
    }
    
    var body: some View {
        NavigationLink(destination: CardDetailsView(cardName: cardName)) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(shadowColor)
                    .brightness(-0.3)
                    .offset(x: 0, y: 5)
                HStack(alignment: .center){
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mainText)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.leading)
                                
                                if let subtitle = subtitle {
                                    Text(subtitle)
                                        .font(.subheadline)
                                    
                                }
                            }
                            
                            Spacer()
                            
                            
                        }
                        Spacer()
                        content
                    }
                    
                    .foregroundColor(foregroundColor)
                    .frame(minWidth: 175, maxWidth: 220, minHeight: 175, alignment: .leading)
                    .padding()
                    .background(backgroundColor)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    Spacer()
                    imageContent
                    Spacer()
                    
                }
            }
            
        }
    }
}
