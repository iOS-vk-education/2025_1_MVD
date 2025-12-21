import SwiftUI

struct SettingsView: View {
    @ObservedObject var userStorage = UserStorage()
    var body: some View {
        Text("Настройки")
            .font(.title)
            .fontWeight(.bold)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
