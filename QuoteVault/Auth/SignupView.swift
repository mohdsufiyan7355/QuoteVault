//
//  SignupView.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import SwiftUI

struct SignupView: View {
    @StateObject private var vm = AuthViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) var dismiss
    @State private var confirmPassword = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                    Text("Create Account")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Join QuoteVault to save your favorite quotes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 20)

                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $vm.email)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)

                    SecureField("Password", text: $vm.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                }
                .padding(.horizontal)
                
                // Password match indicator
                if !confirmPassword.isEmpty && vm.password != confirmPassword {
                    Text("Passwords do not match")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if showSuccess {
                    Text("Account created successfully! Please check your email to verify your account.")
                        .foregroundColor(.green)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Sign Up Button
                Button(action: {
                    Task {
                        if let session = await vm.signUp() {
                            sessionManager.setSession(session)
                            dismiss()
                        } else if vm.errorMessage == nil {
                            // Email confirmation required
                            showSuccess = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                dismiss()
                            }
                        }
                    }
                }) {
                    HStack {
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(vm.isLoading || vm.email.isEmpty || vm.password.isEmpty || vm.password != confirmPassword)
                .padding(.horizontal)

                Spacer()
                
                // Back to Login
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    Button("Login") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .font(.subheadline)
                .padding(.bottom)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}


struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
