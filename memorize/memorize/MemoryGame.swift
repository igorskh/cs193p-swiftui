//
//  MemoryGame.swift
//  CS193p
//
//  Created by Igor Kim on 16.08.20.
//  Copyright © 2020 Igor Kim. All rights reserved.
//

import Foundation

struct MemoryGame<CardContent> where CardContent: Equatable {
    private(set) var cards: Array<Card>
    var score: Int = 0
    var isFinished: Bool {
        get {
            return cards.indices.filter { cards[$0].isMatched }.count == cards.count
        }
    }
    
    private var indexOfFaceUpCard: Int? {
        get {
            return cards.indices.filter { cards[$0].isFaceUp }.only
        }
        set {
            for index in cards.indices {
                cards[index].isFaceUp = index == newValue
            }
        }
    }
    
    mutating private func scoreMatch(firstIndex: Int, secondIndex: Int) {
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

    mutating func flipAllCardsDown() {
        for index in 0..<cards.count {
            cards[index].isFaceUp = false
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
    
    struct Card: Identifiable {
        var id: Int
        
        var isSeen: Bool = false
        var isFaceUp: Bool = false {
            didSet {
                if isFaceUp {
                    startUsingBonusTime()
                } else {
                    stopUsingBonusTime()
                }
            }
        }
        
        var isMatched: Bool = false {
            didSet {
                stopUsingBonusTime()
            }
        }
        var content: CardContent
        
        func scorePenalty() -> Int {
            return isSeen ? 1 : 0
        }
        
        // MARK: - Bonus Time
        
        var lastFaceUpDate: Date?
        var pastFaceUpTime: TimeInterval = 0
        var bonusTimeLimit: TimeInterval = 6
        
        private var faceUpTime: TimeInterval {
            if let lastFaceUpDate = self.lastFaceUpDate {
                return pastFaceUpTime + Date().timeIntervalSince(lastFaceUpDate)
            } else {
                return pastFaceUpTime
            }
        }
        
        var bonusRemaining: Double {
            (bonusTimeLimit > 0 && bonusTimeRemaining > 0) ? bonusTimeRemaining/bonusTimeLimit : 0;
        }
        
        var bonusTimeRemaining: TimeInterval {
            max(0, bonusTimeLimit - faceUpTime)
        }
        
        var hasEarnedBonus: Bool {
            isMatched && bonusTimeRemaining > 0
        }
        
        var isConsumingBonusTime: Bool {
            isFaceUp && !isMatched && bonusTimeRemaining > 0
        }
        
        private mutating func startUsingBonusTime() {
            if isConsumingBonusTime, lastFaceUpDate == nil {
                lastFaceUpDate = Date()
            }
        }
        
        private mutating func stopUsingBonusTime() {
            pastFaceUpTime = faceUpTime
            self.lastFaceUpDate = nil
        }
    }
}
