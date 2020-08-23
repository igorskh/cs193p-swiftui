//
//  EmojiArtDocument.swift
//  emojiart
//
//  Created by Igor Kim on 17.08.20.
//  Copyright © 2020 Igor Kim. All rights reserved.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject, Hashable, Identifiable {
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: UUID
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static let palette: String = "⭐️☁️☀️🦆🏀"
    
    @Published private var emojiArt: EmojiArt = EmojiArt()
    @Published private(set) var backgroundImage: UIImage?
    @Published var steadyStatePanOffset: CGSize = .zero
    @Published var steadyStateZoomScale: CGFloat = 1.0
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    
    private var autosaveCancellable: AnyCancellable?
    
    init(id: UUID? = nil) {
        self.id = id ?? UUID()
        let defaultKey = "EmojiArtDocument.\(self.id.uuidString)"
        
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: defaultKey)) ?? EmojiArt()
        fetchBackgrounImageData()
        autosaveCancellable = $emojiArt.sink {emojiArt in
            UserDefaults.standard.set(emojiArt.json, forKey: defaultKey)
        }
    }
    
    // MARK: - Intent(s)
    
    func removeEmoji(_ emoji: EmojiArt.Emoji) {
        emojiArt.removeEmoji(emoji)
    }
    
    func clearEmojis() {
        emojiArt.clearEmojis()
    }
    
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let i = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[i].x += Int(offset.width)
            emojiArt.emojis[i].y += Int(offset.height)

            print(emojiArt.emojis[i].x, emojiArt.emojis[i].y)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let i = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[i].size = Int(
                (CGFloat(emojiArt.emojis[i].size)*scale).rounded(.toNearestOrEven)
            )
        }
    }
    
    var backgroundURL: URL? {
        get {
            emojiArt.backgrounURL
        }
        set {
            emojiArt.backgrounURL = newValue?.imageURL
            
            fetchBackgrounImageData()
        }
    }
    
    private var fetchImageCancellable: AnyCancellable?
    private func fetchBackgrounImageData() {
        backgroundImage = nil
        if let url = self.emojiArt.backgrounURL {
            fetchImageCancellable?.cancel()
            fetchImageCancellable =  URLSession.shared.dataTaskPublisher(for: url)
                .map { data, _ in UIImage(data: data)}
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil).assign(to: \EmojiArtDocument.backgroundImage, on: self)
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat {CGFloat(self.size)}
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y))}
}
