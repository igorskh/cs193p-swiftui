//
//  EmojiMemoryGameView.swift
//  CS193p
//
//  Created by Igor Kim on 16.08.20.
//  Copyright © 2020 Igor Kim. All rights reserved.
//

import SwiftUI

struct EmojiMemoryGameView: View {
    @ObservedObject var viewModel: EmojiMemoryGame
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Button("New Game") {
                    self.viewModel.newGame()
                }.padding()
                Text("\(viewModel.score)").font(.largeTitle).padding()
                Text(viewModel.theme.name).padding()
            }
            Grid(self.viewModel.cards) {card in
                CardView(card: card).onTapGesture {
                    self.viewModel.chooseCard(card: card)
                }
                .padding(5)
            }
            .foregroundColor(viewModel.theme.cardColor)
            .font(self.viewModel.cards.count/2 > 4 ? .body : .largeTitle)
            
        }
    }
}

struct CardView: View {
    var card: MemoryGame<String>.Card
    
    var body: some View {
        GeometryReader { geometry in
            self.body(for: geometry.size)
        }
    }
    
    func body(for size: CGSize) -> some View {
        ZStack() {
            if card.isFaceUp {
                RoundedRectangle(cornerRadius: conrnerRadius).fill(Color.white)
                RoundedRectangle(cornerRadius: conrnerRadius).stroke(lineWidth: edgeLineWidth)
                Text(card.content)
            } else {
                if !card.isMatched {
                    RoundedRectangle(cornerRadius: conrnerRadius).fill()
                }
            }
        }
        .font(.system(
            size: fontSize(for: size)
            ))
    }
    
    // MARK: - Drawing constants
    
    let conrnerRadius: CGFloat = 10.0
    let edgeLineWidth: CGFloat = 3.0
    func fontSize(for size: CGSize) -> CGFloat {
        return min(size.width, size.height)*0.75
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiMemoryGameView(viewModel: EmojiMemoryGame())
    }
}
