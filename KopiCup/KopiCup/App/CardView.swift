import SwiftUI

struct CardViewModel {
    let cardName: String
    let mainText: String
    let subtitle: String?
    
    let backgroundColor: Color
    let foregroundColor: Color
    let borderColor: Color
    let hasBorder: Bool
    
    init(
        cardName: String = "Карточка",
        mainText: String,
        subtitle: String? = nil,
        backgroundColor: Color = Color(.systemBackground),
        foregroundColor: Color = .secondary,
        borderColor: Color = .clear,
        hasBorder: Bool = false
    ) {
        self.cardName = cardName
        self.mainText = mainText
        self.subtitle = subtitle
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.borderColor = borderColor
        self.hasBorder = hasBorder
    }
    
    var borderWidth: Double { hasBorder ? 3 : 0 }
    
    var shadowColor: Color { hasBorder ? borderColor : backgroundColor }
}

struct CardView<Content: View, ImageContent: View>: View {
    let viewModel: CardViewModel
    let content: Content
    let imageContent: ImageContent
    
    init(
        viewModel: CardViewModel,
        @ViewBuilder content: () -> Content,
        @ViewBuilder imageContent: () -> ImageContent
    ) {
        self.viewModel = viewModel
        self.content = content()
        self.imageContent = imageContent()
    }
    
    var body: some View {
        NavigationLink(destination: CardDetailsView(cardName: viewModel.cardName)) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.shadowColor)
                    .brightness(-0.3)
                    .offset(x: 0, y: 5)
                
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.mainText)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.leading)
                            
                            if let subtitle = viewModel.subtitle {
                                Text(subtitle)
                                    .font(.subheadline)
                            }
                        }
                        Spacer(minLength: 8)
                        content
                    }
                    .foregroundColor(viewModel.foregroundColor)
                    .frame(minWidth: 175, maxWidth: 220, minHeight: 175, alignment: .leading)
                    .padding()
                    .background(viewModel.backgroundColor)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.borderColor, lineWidth: viewModel.borderWidth)
                    )
                    imageContent
                        .frame(minWidth: 80, maxWidth: 120, minHeight: 80, maxHeight: 120)
                        .padding(.trailing, 8)
                }
                .padding(12)
            }
            .padding(.vertical, 6)
        }
    }
}
