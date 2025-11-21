import SwiftUI

struct StatsView: View {
    @ObservedObject var userStorage = UserStorage()
    var body: some View {
        Text("Статистика")
            .font(.title)
            .fontWeight(.bold)
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
