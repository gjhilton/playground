import SwiftUI
import UIKit

struct ContentView: View {
    @State private var scraps: [Scrap] = []
    @State private var scrapCount: Int = 0
    
    private let fontName = "TT2020StyleE-Regular"
    private let fontSize: CGFloat = 36
    
    var body: some View {
        GeometryReader { geometry in
            let scrapWidth = geometry.size.width * 0.9
            
            VStack(spacing: 0) {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(scraps) { scrap in
                                TextScrapView(
                                    text: scrap.text,
                                    font: scrap.font,
                                    isEditable: false,
                                    isScrollEnabled: false
                                )
                                .frame(
                                    width: scrapWidth,
                                    height: TextScrapView.calculateHeight(for: scrap.text, font: scrap.font, borderPadding: 20)
                                )
                                .id(scrap.id)
                            }
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 100) // Prevent overlap with button area
                        .onChange(of: scraps.count) { _ in
                            if let last = scraps.last {
                                DispatchQueue.main.async {
                                    scrollProxy.scrollTo(last.id, anchor: .center)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Spacer()
                    Button("Add Scrap") {
                        addScrap()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .cornerRadius(8)
                    Spacer()
                }
                .padding()
                .background(Color(white: 0.95))
            }
            .background(Color.white.ignoresSafeArea())
            .onAppear {
                FontRegistrar.registerFont(withName: fontName, fileExtension: "ttf")
            }
        }
    }
    
    private func addScrap() {
        scrapCount += 1
        let text = "\(scrapCount). " + generateRandomLorem()
        let font = UIFont(name: fontName, size: fontSize) ?? .systemFont(ofSize: fontSize)
        let newScrap = Scrap(id: UUID(), text: text, font: font)
        scraps.append(newScrap)
    }
    
    private func generateRandomLorem() -> String {
        let sentences = loremSentences.shuffled()
        let count = Int.random(in: 2...5)
        return sentences.prefix(count).joined(separator: " ")
    }
    
    private let loremSentences: [String] = [
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
        "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
        "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
        "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
        "At vero eos et accusamus et iusto odio dignissimos ducimus.",
        "Qui blanditiis praesentium voluptatum deleniti atque corrupti.",
        "Quos dolores et quas molestias excepturi sint occaecati cupiditate non provident.",
        "Similique sunt in culpa qui officia deserunt mollitia animi.",
        "Id est laborum et dolorum fuga."
    ]
}

struct Scrap: Identifiable {
    let id: UUID
    let text: String
    let font: UIFont
}
