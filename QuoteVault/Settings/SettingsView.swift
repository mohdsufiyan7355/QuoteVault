//
//  SettingsView.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var profileVM = ProfileViewModel()
    @State private var showingProfile = false
    @State private var showingPasswordReset = false
    @State private var notificationHour = AppConstants.Notification.defaultNotificationHour
    @State private var notificationMinute = AppConstants.Notification.defaultNotificationMinute
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let session = sessionManager.session {
                        NavigationLink(destination: ProfileView(profileVM: profileVM)) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(profileVM.profile?.name ?? session.user.email ?? "User")
                                        .font(.headline)
                                    Text(session.user.email ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $themeManager.isDarkMode)
                        .onChange(of: themeManager.isDarkMode) { _ in
                            themeManager.saveSettings()
                        }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Font Size: \(Int(themeManager.fontSize))pt")
                            .font(.subheadline)
                        Slider(value: $themeManager.fontSize, in: 12...24, step: 1)
                            .onChange(of: themeManager.fontSize) { _ in
                                themeManager.saveSettings()
                                Task {
                                    await saveFontSizeSettings()
                                }
                            }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Notifications") {
                    Toggle("Daily Quote Notification", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "notificationsEnabled") },
                        set: { enabled in
                            UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")
                            if enabled {
                                NotificationManager.shared.scheduleDailyQuote(
                                    hour: notificationHour,
                                    minute: notificationMinute
                                )
                            } else {
                                NotificationManager.shared.cancelDailyQuote()
                            }
                        }
                    ))
                    
                    DatePicker("Notification Time", selection: Binding(
                        get: {
                            var components = DateComponents()
                            components.hour = notificationHour
                            components.minute = notificationMinute
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            notificationHour = components.hour ?? AppConstants.Notification.defaultNotificationHour
                            notificationMinute = components.minute ?? AppConstants.Notification.defaultNotificationMinute
                            if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                                NotificationManager.shared.scheduleDailyQuote(
                                    hour: notificationHour,
                                    minute: notificationMinute
                                )
                            }
                        }
                    ), displayedComponents: .hourAndMinute)
                }
                
                Section("Account") {
                    Button(action: { showingPasswordReset = true }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.blue)
                            Text("Reset Password")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await sessionManager.signOut()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Logout")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPasswordReset) {
                PasswordResetView()
            }
            .task {
                await loadProfile()
                await requestNotificationPermission()
            }
        }
    }
    
    private func loadProfile() async {
        guard let userId = sessionManager.session?.user.id else { return }
        await profileVM.loadProfile(userId: userId)
    }
    
    private func saveFontSizeSettings() async {
        guard let userId = sessionManager.session?.user.id else { return }
        _ = await profileVM.updateProfile(
            name: profileVM.profile?.name,
            avatarUrl: profileVM.profile?.avatarUrl,
            theme: profileVM.profile?.theme,
            fontSize: themeManager.fontSize,
            notificationTime: nil,
            userId: userId
        )
    }
    
    private func requestNotificationPermission() async {
        let granted = await NotificationManager.shared.requestAuthorization()
        if granted {
            if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                NotificationManager.shared.scheduleDailyQuote(
                    hour: notificationHour,
                    minute: notificationMinute
                )
            }
        }
    }
}

struct ProfileView: View {
    @ObservedObject var profileVM: ProfileViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @State private var name = ""
    @State private var isSaved = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section("Profile Information") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
            }
            
            Section {
                Button(action: saveProfile) {
                    HStack {
                        Spacer()
                        if profileVM.isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                        Spacer()
                    }
                }
                .disabled(profileVM.isLoading)
            }
            
            if isSaved {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Profile saved successfully!")
                            .foregroundColor(.green)
                    }
                }
            }
            
            if let error = profileVM.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            name = profileVM.profile?.name ?? ""
        }
    }
    
    private func saveProfile() {
        Task {
            guard let userId = sessionManager.session?.user.id else { return }
            let success = await profileVM.updateProfile(
                name: name.isEmpty ? nil : name,
                avatarUrl: profileVM.profile?.avatarUrl,
                theme: profileVM.profile?.theme,
                fontSize: profileVM.profile?.fontSize,
                notificationTime: profileVM.profile?.notificationTime,
                userId: userId
            )
            if success {
                isSaved = true
                // Hide success message after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isSaved = false
                }
            }
        }
    }
}

struct PasswordResetView: View {
    @StateObject private var authVM = AuthViewModel()
    @State private var email = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                } header: {
                    Text("Enter your email to receive password reset instructions")
                }
                
                if let error = authVM.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Reset Password")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        Task {
                            await authVM.resetPassword(email: email)
                            if authVM.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(email.isEmpty || authVM.isLoading)
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
