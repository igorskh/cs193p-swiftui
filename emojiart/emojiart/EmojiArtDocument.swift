//
//  EmojiArtDocument.swift
//  emojiart
//
//  Created by Igor Kim on 17.08.20.
//  Copyright © 2020 Igor Kim. All rights reserved.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    
    static let palette: String = "⭐️☁️☀️🦆🏀"
    private static let untitled = "EmojiArtDocument.Untitled"
    
    @Published private var emojiArt: EmojiArt = EmojiArt() {
        didSet {
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
    }
    @Published private(set) var backgroundImage: UIImage?
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    
    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        fetchBackgrounImageData()
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
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let i = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[i].size = Int(
                (CGFloat(emojiArt.emojis[i].size)*scale).rounded(.toNearestOrEven)
            )
        }
    }
    
    func setBackgroundURL(_ url: URL?) {
        emojiArt.backgrounURL = url?.imageURL
        
        fetchBackgrounImageData()
    }
    
    private func fetchBackgrounImageData() {
        backgroundImage = nil
        if let url = self.emojiArt.backgrounURL {
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        if url == self.emojiArt.backgrounURL {
                            self.backgroundImage = UIImage(data: imageData)
                        }
                    }
                }
            }
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat {CGFloat(self.size)}
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y))}
}
