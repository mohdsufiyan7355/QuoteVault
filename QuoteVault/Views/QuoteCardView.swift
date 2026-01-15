//
//  QuoteCardView.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import SwiftUI

struct QuoteCardView: View {
    let quote: Quote
    let style: CardStyle
    @Environment(\.colorScheme) var colorScheme
    @State private var renderedImage: UIImage?
    
    enum CardStyle: String, CaseIterable {
        case minimal = "Minimal"
        case gradient = "Gradient"
        case elegant = "Elegant"
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                cardBackground
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("\"\(quote.text)\"")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(8)
                    
                    Text("- \(quote.author)")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundColor(textColor.opacity(0.8))
                        .padding(.top, 8)
                    
                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                renderImage(size: geometry.size)
            }
        }
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .minimal:
            Color(.systemBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                )
        case .gradient:
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.8),
                    Color.accentColor.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .elegant:
            ZStack {
                Color(.systemBackground)
                Image(systemName: "quote.opening")
                    .font(.system(size: 200))
                    .foregroundColor(Color.primary.opacity(0.05))
            }
        }
    }
    
    private var textColor: Color {
        switch style {
        case .minimal, .elegant:
            return Color.primary
        case .gradient:
            return .white
        }
    }
    
    private func renderImage(size: CGSize) {
        let renderer = UIGraphicsImageRenderer(size: size)
        renderedImage = renderer.image { context in
            let hostingController = UIHostingController(rootView: self)
            hostingController.view.frame = CGRect(origin: .zero, size: size)
            hostingController.view.backgroundColor = .clear
            hostingController.view.layer.render(in: context.cgContext)
        }
    }
    
    func saveToPhotos() {
        guard let image = renderedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

struct QuoteCardGeneratorView: View {
    let quote: Quote
    @State private var selectedStyle: QuoteCardView.CardStyle = .minimal
    @State private var showingShareSheet = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Style Picker
                Picker("Style", selection: $selectedStyle) {
                    ForEach(QuoteCardView.CardStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Card Preview
                QuoteCardView(quote: quote, style: selectedStyle)
                    .frame(height: 400)
                    .padding()
                
                // Actions
                HStack(spacing: 20) {
                    Button(action: {
                        // Save to photos
                        // Note: In a real implementation, you'd need to properly render and save
                    }) {
                        Label("Save", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: { showingShareSheet = true }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Quote Card")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: ["\"\(quote.text)\" - \(quote.author)"])
            }
        }
    }
}
