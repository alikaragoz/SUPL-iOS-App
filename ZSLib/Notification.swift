import Foundation

public enum CurrentUserNotifications {
  public static let showNotificationsDialog = "CurrentUserNotifications.showNotificationsDialog"
}

extension Notification.Name {
  public static let zs_showNotificationsDialog =
    Notification.Name(rawValue: CurrentUserNotifications.showNotificationsDialog)
}
