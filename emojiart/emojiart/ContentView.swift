//
//  ContentView.swift
//  emojiart
//
//  Created by Igor Kim on 17.08.20.
//  Copyright © 2020 Igor Kim. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    var body: some View {
        Text("Hello, World!")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView()
    }
}
