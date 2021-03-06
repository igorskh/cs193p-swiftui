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
    
    func newGame() {
        // TODO: Animate fipping cards down
        viewModel.flipAllCardsDown()
        withAnimation(.easeInOut) {
            self.viewModel.newGame()
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text("\(viewModel.score)")
                    .font(.largeTitle)
                    .padding()
                    .animation(.none)
            }
            Grid(self.viewModel.cards) {card in
                CardView(card: card).onTapGesture {
                    if self.viewModel.isFinished {
                        self.newGame()
                    } else {
                        withAnimation(.linear(duration: 0.75)) {
                            self.viewModel.chooseCard(card: card)
                        }
                    }
                }
                .padding(5)
            }
            .padding()
            .foregroundColor(viewModel.theme.cardColor)
            .font(self.viewModel.cards.count/2 > 4 ? .body : .largeTitle)
            
            HStack {
                Button("New Game") {
                    self.newGame()
                }.padding()
                
                Text(viewModel.theme.name) .padding()
            }
            .animation(.none)
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
    
    @State private var animatedBonusRemaining: Double = 0
    private func startBonusTimeAnimation() {
        animatedBonusRemaining = card.bonusRemaining
        withAnimation(.linear(duration: card.bonusTimeRemaining)) {
            animatedBonusRemaining = 0
        }
    }
    
    @ViewBuilder
    private func body(for size: CGSize) -> some View {
        if card.isFaceUp || !card.isMatched {
            Group() {
                Group {
                    if card.isConsumingBonusTime {
                        Pie(
                            startAngle: Angle.degrees(0-90),
                            endAngle: Angle.degrees(-animatedBonusRemaining*360-90)
                        ).onAppear {self.startBonusTimeAnimation()}
                            .transition(.scale)
                    } else {
                        Pie(
                            startAngle: Angle.degrees(0-90),
                            endAngle: Angle.degrees(-card.bonusRemaining*360-90)
                        ).transition(.identity)
                        
                    }
                }
                .padding(2)
                .opacity(0.4)
                
                
                Text(card.content)
                    .font(.system(size: fontSize(for: size)))
                    .rotationEffect(Angle.degrees(card.isMatched ? 360 : 0))
                    .animation(card.isMatched
                        ? Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
                        : Animation.default)
            }
            .cardify(isFaceUp: card.isFaceUp)
            .transition(.scale)
        }
    }
    
    // MARK: - Drawing constants
    
    private func fontSize(for size: CGSize) -> CGFloat {
        return min(size.width, size.height)*0.70
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let game = EmojiMemoryGame()
        game.chooseCard(card: game.cards[0])
        return EmojiMemoryGameView(viewModel: game)
    }
}
