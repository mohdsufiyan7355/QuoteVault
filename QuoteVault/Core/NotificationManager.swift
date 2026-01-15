//
//  NotificationManager.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    func scheduleDailyQuote(hour: Int = AppConstants.Notification.defaultNotificationHour, minute: Int = AppConstants.Notification.defaultNotificationMinute) {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications
        center.removePendingNotificationRequests(withIdentifiers: [AppConstants.Notification.dailyQuoteIdentifier])
        
        let content = UNMutableNotificationContent()
        content.title = "Quote of the Day"
        content.body = "Check out today's inspiring quote!"
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: AppConstants.Notification.dailyQuoteIdentifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelDailyQuote() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [AppConstants.Notification.dailyQuoteIdentifier])
    }
}
