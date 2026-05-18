import Foundation
import SwiftUI
import Combine

// MARK: - L10n (per-app language, не зависит от настроек устройства)

enum AppLanguage: String, CaseIterable {
    case ru, en
}

final class L10n: ObservableObject {
    static let shared = L10n()
    @Published var language: AppLanguage

    private var cancellable: AnyCancellable?

    private init() {
        let code = UserDefaults.standard.string(forKey: "settings.language.code") ?? "ru"
        language = AppLanguage(rawValue: code) ?? .ru

        // KVO через \.settingsLanguageCode не срабатывает: имя KVO-property ("settingsLanguageCode")
        // не совпадает с ключом UserDefaults ("settings.language.code"), поэтому уведомления не приходят.
        // Используем UserDefaults.didChangeNotification — надёжный способ отловить любое изменение.
        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .compactMap { _ in UserDefaults.standard.string(forKey: "settings.language.code") }
            .removeDuplicates()
            .sink { [weak self] newCode in
                guard let self else { return }
                self.language = AppLanguage(rawValue: newCode) ?? .ru
            }
    }

    /// Locale для форматтеров (DateFormatter, NumberFormatter) — следует за выбранным языком.
    var locale: Locale {
        switch language {
        case .ru: return Locale(identifier: "ru_RU")
        case .en: return Locale(identifier: "en_US")
        }
    }

    func t(_ key: Key, _ args: CVarArg...) -> String {
        let format = translations[language]?[key.rawValue] ?? key.rawValue
        if args.isEmpty { return format }
        else { return String(format: format, arguments: args) }
    }

    enum Key: String {
        // Home
        case weeklySaved = "home.weekly.saved"
        case keepGoing = "home.keep.going"
        case noGoal = "home.alert.no_goal_title"
        case ok
        case homeGreeting = "home.greeting"
        case openPiggy = "home.open_piggy"
        case challengeFailed = "home.challenge_failed"
        case challengeFailedMsg = "home.challenge_failed_msg"
        case challengeCompleted = "home.challenge_completed"
        case challengeCompletedMsg = "home.challenge_completed_msg"
        case tryAgain = "home.try_again"
        // Tab bar
        case tabHome = "tab.home"
        case tabStats = "tab.stats"
        case tabProfile = "tab.profile"
        // Stats
        case statsTitle = "stats.title"
        case statsSubtitle = "stats.subtitle"
        case statsWeeklyChart = "stats.chart.weekly"
        case statsMonthlyChart = "stats.chart.monthly"
        case statsRadarChart = "stats.chart.radar"
        case statsThisWeek = "stats.this_week"
        case statsThisMonth = "stats.this_month"
        case statsAvgPerDay = "stats.avg_per_day"
        case statsStrengths = "stats.strengths"
        case statsWeaknesses = "stats.weaknesses"
        // Profile
        case profileAchievements = "profile.achievements"
        case profileSettings = "profile.settings"
        case darkTheme = "profile.dark_theme"
        case currency = "profile.currency"
        case language = "profile.language"
        case logout = "profile.logout"
        case logoutConfirm = "profile.logout.confirm"
        case logoutReturn = "profile.logout.return"
        case cancel = "cancel"
        case save = "save"
        case editName = "profile.edit_name"
        case yourName = "profile.your_name"
        case chooseFromGallery = "profile.gallery"
        case takePhoto = "profile.camera"
        case deletePhoto = "profile.delete_photo"
        case savingSince = "profile.saving_since"
        // Achievements
        case achievLightningStart = "achiev.lightning_start"
        case achievFirstTopup = "achiev.first_topup"
        case achievSevenDays = "achiev.seven_days"
        case achievGoalReached = "achiev.goal_reached"
        case achievThirtyDays = "achiev.thirty_days"
        case achievBestFriend = "achiev.best_friend"
        // Weekday short names
        case mon = "weekday.mon"
        case tue = "weekday.tue"
        case wed = "weekday.wed"
        case thu = "weekday.thu"
        case fri = "weekday.fri"
        case sat = "weekday.sat"
        case sun = "weekday.sun"
        // Goal card
        case goalCollected = "goal.card.collected"
        case goalTarget = "goal.card.target"
        // Goal details
        case goalDetailsTitle = "goal.details.title"
        case goalDetailsImagePlaceholder = "goal.details.image_placeholder"
        // About goal sheet
        case aboutGoalProgress = "goal.about.progress"
        case aboutGoalRemaining = "goal.about.remaining"
        case aboutGoalDeadline = "goal.about.deadline"
        case aboutGoalViewProduct = "goal.about.view_product"
        case aboutGoalTopUp = "goal.about.top_up"
        // Challenge card
        case challengeNone = "challenge.card.none"
        case challengeTrackToday = "challenge.card.track_today"
        case challengeAccept = "challenge.card.accept"
        case challengeNext = "challenge.card.next"
        case challengeDifficulty = "challenge.card.difficulty"
        // Add money sheet
        case addMoneyTitle = "addmoney.title"
        case addMoneySavedOf = "addmoney.saved_of"
        case addMoneyPlaceholder = "addmoney.placeholder"
        case addMoneyAdd = "addmoney.add"
        case addMoneyCloseGoal = "addmoney.close_goal"
        // Challenge detail modal
        case challengeDetailPeriod = "challenge.detail.period"
        case challengeDetailProgress = "challenge.detail.progress"
        case challengeDetailMarkToday = "challenge.detail.mark_today"
        case challengeDetailMarkedToday = "challenge.detail.marked_today"
        case challengeDetailDecline = "challenge.detail.decline"
        case challengeDetailDeclineConfirm = "challenge.detail.decline_confirm"
        case challengeDetailDeclineAction = "challenge.detail.decline_action"
        case challengeFallbackName = "challenge.fallback_name"
        // Series card
        case seriesWeeklySaved = "series.weekly_saved"
        case seriesKeepGoing = "series.keep_going"
        case seriesNoGoal = "series.no_goal"
    }

    private let translations: [AppLanguage: [String: String]] = [
        .ru: [
            // Home
            "home.weekly.saved": "На этой неделе накоплено:\n%@",
            "home.keep.going": "Так держать!",
            "home.alert.no_goal_title": "Сначала добавьте цель!",
            "ok": "Ок",
            "home.greeting": "Привет, %@!",
            "home.open_piggy": "Открыть копилку",
            "home.challenge_failed": "Челлендж провален",
            "home.challenge_failed_msg": "Ты пропустил день в челлендже «%@». Не расстраивайся — каждый новый день это шанс начать заново!",
            "home.challenge_completed": "Челлендж завершён",
            "home.challenge_completed_msg": "Поздравляем! Челлендж «%@» завершён. Вы продержались %d дн.",
            "home.try_again": "Попробую снова!",
            // Tab bar
            "tab.home": "Главная",
            "tab.stats": "Статистика",
            "tab.profile": "Профиль",
            // Stats
            "stats.title": "Статистика",
            "stats.subtitle": "Отслеживайте свои накопления",
            "stats.chart.weekly": "Накопления за неделю",
            "stats.chart.monthly": "Динамика по месяцам",
            "stats.chart.radar": "Сильные и слабые стороны",
            "stats.this_week": "Эта неделя",
            "stats.this_month": "Этот месяц",
            "stats.avg_per_day": "Ср. / день",
            "stats.strengths": "Сильные стороны",
            "stats.weaknesses": "Нужно подтянуть",
            // Profile
            "profile.achievements": "Достижения",
            "profile.settings": "Настройки",
            "profile.dark_theme": "Темная тема",
            "profile.currency": "Валюта",
            "profile.language": "Язык",
            "profile.logout": "Выйти из аккаунта",
            "profile.logout.confirm": "Вы действительно хотите выйти?",
            "profile.logout.return": "Вы вернётесь на экран входа.",
            "cancel": "Отмена",
            "save": "Сохранить",
            "profile.edit_name": "Изменить имя",
            "profile.your_name": "Ваше имя",
            "profile.gallery": "Выбрать из галереи",
            "profile.camera": "Сделать фото",
            "profile.delete_photo": "Удалить фото",
            "profile.saving_since": "Копит с",
            // Achievements
            "achiev.lightning_start": "Мощный старт",
            "achiev.first_topup": "Первое пополнение",
            "achiev.seven_days": "7 дней подряд",
            "achiev.goal_reached": "Цель достигнута",
            "achiev.thirty_days": "30 дней подряд",
            "achiev.best_friend": "Лучший друг",
            // Weekdays
            "weekday.mon": "Пн",
            "weekday.tue": "Вт",
            "weekday.wed": "Ср",
            "weekday.thu": "Чт",
            "weekday.fri": "Пт",
            "weekday.sat": "Сб",
            "weekday.sun": "Вс",
            // Goal card
            "goal.card.collected": "Собрано:",
            "goal.card.target": "Цель:",
            // Goal details
            "goal.details.title": "Детали",
            "goal.details.image_placeholder": "Изображение появится позже",
            // About goal sheet
            "goal.about.progress": "Прогресс",
            "goal.about.remaining": "Осталось",
            "goal.about.deadline": "Дата цели",
            "goal.about.view_product": "Посмотреть товар",
            "goal.about.top_up": "Пополнить копилку",
            // Challenge card
            "challenge.card.none": "Нет челленджа",
            "challenge.card.track_today": "Отмечайте свои успехи сегодня",
            "challenge.card.accept": "Принимаю",
            "challenge.card.next": "Другой",
            "challenge.card.difficulty": "Сложность: %d из %d",
            // Add money sheet
            "addmoney.title": "Пополнить копилку",
            "addmoney.saved_of": "Накоплено: %@ из %@",
            "addmoney.placeholder": "Введите сумму %@",
            "addmoney.add": "Добавить",
            "addmoney.close_goal": "Закрыть цель (%@)",
            // Challenge detail modal
            "challenge.detail.period": "Период челленджа",
            "challenge.detail.progress": "Прогресс",
            "challenge.detail.mark_today": "Отметить сегодня",
            "challenge.detail.marked_today": "Отмечено сегодня",
            "challenge.detail.decline": "✗ Отказаться от челленджа",
            "challenge.detail.decline_confirm": "Вы уверены, что хотите отказаться от челленджа?",
            "challenge.detail.decline_action": "Отказаться",
            "challenge.fallback_name": "Челлендж",
            // Series card
            "series.weekly_saved": "За неделю накоплено %@",
            "series.keep_going": "Продолжай в том же духе!",
            "series.no_goal": "Сначала создай цель"
        ],
        .en: [
            // Home
            "home.weekly.saved": "Saved this week:\n%@",
            "home.keep.going": "Keep it up!",
            "home.alert.no_goal_title": "Add a goal first!",
            "ok": "OK",
            "home.greeting": "Hi, %@!",
            "home.open_piggy": "Open piggy bank",
            "home.challenge_failed": "Challenge failed",
            "home.challenge_failed_msg": "You missed a day in the \"%@\" challenge. Don't worry — every new day is a chance to start fresh!",
            "home.challenge_completed": "Challenge completed",
            "home.challenge_completed_msg": "Congratulations! The \"%@\" challenge is over. You kept going for %d days.",
            "home.try_again": "I'll try again!",
            // Tab bar
            "tab.home": "Home",
            "tab.stats": "Statistics",
            "tab.profile": "Profile",
            // Stats
            "stats.title": "Statistics",
            "stats.subtitle": "Track your savings",
            "stats.chart.weekly": "Weekly savings",
            "stats.chart.monthly": "Monthly dynamics",
            "stats.chart.radar": "Strengths & weaknesses",
            "stats.this_week": "This week",
            "stats.this_month": "This month",
            "stats.avg_per_day": "Avg / day",
            "stats.strengths": "Strengths",
            "stats.weaknesses": "Needs work",
            // Profile
            "profile.achievements": "Achievements",
            "profile.settings": "Settings",
            "profile.dark_theme": "Dark theme",
            "profile.currency": "Currency",
            "profile.language": "Language",
            "profile.logout": "Sign out",
            "profile.logout.confirm": "Are you sure you want to log out?",
            "profile.logout.return": "You will return to the login screen.",
            "cancel": "Cancel",
            "save": "Save",
            "profile.edit_name": "Edit name",
            "profile.your_name": "Your name",
            "profile.gallery": "Choose from gallery",
            "profile.camera": "Take a photo",
            "profile.delete_photo": "Delete photo",
            "profile.saving_since": "Saving since",
            // Achievements
            "achiev.lightning_start": "Strong Start",
            "achiev.first_topup": "First Top-up",
            "achiev.seven_days": "7 Days in a Row",
            "achiev.goal_reached": "Goal Reached",
            "achiev.thirty_days": "30 Days in a Row",
            "achiev.best_friend": "Best Friend",
            // Weekdays
            "weekday.mon": "Mon",
            "weekday.tue": "Tue",
            "weekday.wed": "Wed",
            "weekday.thu": "Thu",
            "weekday.fri": "Fri",
            "weekday.sat": "Sat",
            "weekday.sun": "Sun",
            // Goal card
            "goal.card.collected": "Saved:",
            "goal.card.target": "Goal:",
            // Goal details
            "goal.details.title": "Details",
            "goal.details.image_placeholder": "Image coming soon",
            // About goal sheet
            "goal.about.progress": "Progress",
            "goal.about.remaining": "Remaining",
            "goal.about.deadline": "Goal date",
            "goal.about.view_product": "View product",
            "goal.about.top_up": "Top up",
            // Challenge card
            "challenge.card.none": "No challenge",
            "challenge.card.track_today": "Track your progress today",
            "challenge.card.accept": "Accept",
            "challenge.card.next": "Other",
            "challenge.card.difficulty": "Difficulty: %d of %d",
            // Add money sheet
            "addmoney.title": "Top up piggy bank",
            "addmoney.saved_of": "Saved: %@ of %@",
            "addmoney.placeholder": "Enter amount %@",
            "addmoney.add": "Add",
            "addmoney.close_goal": "Close goal (%@)",
            // Challenge detail modal
            "challenge.detail.period": "Challenge period",
            "challenge.detail.progress": "Progress",
            "challenge.detail.mark_today": "Mark today",
            "challenge.detail.marked_today": "Marked today",
            "challenge.detail.decline": "✗ Decline challenge",
            "challenge.detail.decline_confirm": "Are you sure you want to decline the challenge?",
            "challenge.detail.decline_action": "Decline",
            "challenge.fallback_name": "Challenge",
            // Series card
            "series.weekly_saved": "Saved this week: %@",
            "series.keep_going": "Keep it up!",
            "series.no_goal": "Create a goal first"
        ]
    ]
}

// Note: KVO extension for settingsLanguageCode was removed.
// L10n now uses UserDefaults.didChangeNotification which is reliable
// regardless of whether the key name matches the property name.

// MARK: - Auth localized strings (legacy stub)

enum AuthStrings {
    enum Auth {
        enum Password {
            static let tooWeak = String(localized: "auth.password.error.too_weak")
            static func tooShort(_ min: Int) -> String {
                let format = NSLocalizedString("auth.password.error.too_short",
                                               comment: "Password too short format")
                return String(format: format, locale: .current, min)
            }
        }
        enum Email {
            static let invalid = String(localized: "auth.email.error.invalid")
        }
        enum ConfirmPassword {
            static let mismatch = String(localized: "auth.password.error.mismatch")
        }
    }
}
