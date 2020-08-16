//
//  EmojiMemoryGame.swift
//  CS193p
//
//  Created by Igor Kim on 16.08.20.
//  Copyright © 2020 Igor Kim. All rights reserved.
//

import SwiftUI

let themes: [ThemedMemoryGame] = [
    ThemedMemoryGame(name: "Halloween",
                     emojiSet: ["👻", "🎃", "🕷", "🐍", "🍭", "🧟‍♀️"],
                     cardColor: .orange,
                     numberOfPairs: 4),
    ThemedMemoryGame(name: "Animals",
                     emojiSet: ["🐶", "😼", "🐴", "🐸", "🐼", "🐹"],
                     cardColor: .green,
                     numberOfPairs: 3),
     ThemedMemoryGame(name: "Food",
                      emojiSet: ["🍖", "🍔", "🍕", "🍣", "🍪", "🥟"],
                      cardColor: .red,
                      numberOfPairs: 3)
]

class EmojiMemoryGame: ObservableObject {
    var theme: ThemedMemoryGame = themes[0]
    @Published private var model: MemoryGame<String> = createMemoryGame(themes[0])
    
    private static func createMemoryGame(_ theme: ThemedMemoryGame) -> MemoryGame<String> {
        let emojis: Array<String> = theme.emojiSet.shuffled()
        return MemoryGame<String>(numberOfPairsOfCards: theme.numberOfPairs) { i in emojis[i] }
    }
    
    func newGame() {
        theme = themes.randomElement()!
        model = EmojiMemoryGame.createMemoryGame(theme)
    }
    
    // MARK: - access to the model
    
    var cards: Array<MemoryGame<String>.Card> {
        model.cards
    }
    
    var score: Int {
        model.score
    }
    
    // MARK: - intent(s)
    
    func chooseCard(card: MemoryGame<String>.Card) {
        model.choose(card: card)
    }
    
    func flipAllCardsDown() {
        model.flipAllCardsDown()
    }
}

struct ThemedMemoryGame {
    var name: String
    var emojiSet: Array<String>
    var cardColor: Color
    var numberOfPairs: Int
    
    init(name: String, emojiSet: Array<String>, cardColor: Color, numberOfPairs: Int? =  nil) {
        self.name = name
        self.emojiSet = emojiSet
        self.cardColor = cardColor
        self.numberOfPairs = numberOfPairs ?? Int.random(in: 2...emojiSet.count)
    }
}
