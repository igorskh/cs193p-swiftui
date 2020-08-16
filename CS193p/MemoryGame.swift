//
//  MemoryGame.swift
//  CS193p
//
//  Created by Igor Kim on 16.08.20.
//  Copyright © 2020 Igor Kim. All rights reserved.
//

import Foundation

struct MemoryGame<CardContent> where CardContent: Equatable {
    var cards: Array<Card>
    var score: Int = 0
    var isFinished: Bool {
        get {
            return cards.indices.filter { cards[$0].isMatched }.count == cards.count
        }
    }
    var indexOfFaceUpCard: Int? {
        get {
            return cards.indices.filter { cards[$0].isFaceUp }.only
        }
        set {
            for index in cards.indices {
                cards[index].isFaceUp = index == newValue
            }
        }
    }
    
    init(numberOfPairsOfCards: Int, cardContentFactory: (Int) -> CardContent) {
        cards = Array<Card>()
        for i in 0..<numberOfPairsOfCards {
            let content = cardContentFactory(i);
            cards.append(Card(id: i*2, content: content))
            cards.append(Card(id: i*2+1, content: content))
        }
        cards.shuffle()
    }
    
    mutating func scoreMatch(firstIndex: Int, secondIndex: Int) {
        if cards[firstIndex].content == cards[secondIndex].content {
            // Matched
            cards[firstIndex].isMatched = true
            cards[secondIndex].isMatched = true
            score += 2
        } else {
            // Did not match
            score -= cards[firstIndex].scorePenalty() + cards[secondIndex].scorePenalty()
            
            cards[firstIndex].isSeen = true
            cards[secondIndex].isSeen = true
        }
        
    }
    
    mutating func choose(card: Card) {
        if let chosenIndex = cards.firstIndex(matching: card), !cards[chosenIndex].isFaceUp, !cards[chosenIndex].isMatched {
            if let potentialIndex = indexOfFaceUpCard {
                scoreMatch(firstIndex: potentialIndex, secondIndex: chosenIndex)
                cards[chosenIndex].isFaceUp = true
            } else {
                // No other cards are open
                indexOfFaceUpCard = chosenIndex
            }
        }
    }
    
    struct Card: Identifiable {
        var id: Int
        
        var isSeen: Bool = false
        var isFaceUp: Bool = false
        var isMatched: Bool = false
        var content: CardContent
        
        func scorePenalty() -> Int {
            return isSeen ? 1 : 0
        }
    }
}
