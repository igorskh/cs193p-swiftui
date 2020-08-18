//
//  EmojiArtDocumentView.swift
//  emojiart
//
//  Created by Igor Kim on 17.08.20.
//  Copyright © 2020 Igor Kim. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(EmojiArtDocument.palette.map{ String($0) }, id: \.self) {emoji in
                        Text(emoji)
                            .font(Font.system(size: self.defaultEmojiSize))
                            .onDrag{ NSItemProvider(object: emoji as NSString) }
                    }
                }
            }.padding(.horizontal)
            
            
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffset)
                    )
                        // TODO: deal with delay on single tap ?
                        .gesture(self.doubleTapToZoom(in: geometry.size))
                        .gesture(self.tapToUnselect())
                    
                    
                    ForEach(self.document.emojis) {emoji in
                        ZStack {
                            Text(emoji.text)
                                .border(Color.gray, width: self.emojiSelection.contains(matching: emoji) ? 2 : 0)
                                .font(animatableWithSize: emoji.fontSize*self.zoomScale*(self.emojiSelection.contains(matching: emoji) ? self.emojiZoomScale : 1.0))
                                .position(self.position(for: emoji, in: geometry.size))
                                .onTapGesture {
                                    self.toggleSelection(emoji: emoji)
                            }
                        }
                    }
                }
                .clipped()
                .gesture(self.panGesture())
                .gesture(self.zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
                    return self.drop(providers: providers, at: location)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    
                    Button(action: {
                        self.document.clearEmojis()
                        self.document.setBackgroundURL(nil)
                    }) {
                        Image(systemName: "clear")
                    }
                    if emojiSelection.count > 0 {
                        Button(action: {
                            while self.emojiSelection.count > 0 {
                                let emoji = self.emojiSelection.popLast()!
                                self.document.removeEmoji(emoji)
                            }
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                    
                }.padding(10.0)
                    .font(.largeTitle)
            }
        }
    }
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @State private var emojiSelection = [EmojiArt.Emoji]()
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    @GestureState private var emojiZoomScale: CGFloat = 1.0
    
    private func toggleSelection(emoji: EmojiArt.Emoji) {
        if let i = emojiSelection.firstIndex(matching: emoji) {
            emojiSelection.remove(at: i)
        } else {
            emojiSelection.append(emoji)
        }
    }
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func tapToUnselect()-> some Gesture  {
        TapGesture().onEnded {
            self.emojiSelection.removeAll()
        }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2).onEnded {
            withAnimation {
                self.zoomToFit(self.document.backgroundImage, in: size)
            }
        }
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating(emojiSelection.count > 0 ? $emojiZoomScale : $gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
        }
        .onEnded { finalGestureScale in
            if self.emojiSelection.count > 0 {
                for i in 0..<self.emojiSelection.count {
                    self.document.scaleEmoji(self.emojiSelection[i], by: finalGestureScale)
                }
            } else {
                self.steadyStateZoomScale *= finalGestureScale
            }
        }
    }
    
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    @GestureState private var gestureEmojiOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating(emojiSelection.count > 0 ? $gestureEmojiOffset : $gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                if self.emojiSelection.count > 0 {
                    gesturePanOffset = latestDragGestureValue.translation
                } else {
                    gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
                }
        }
        .onEnded { finalDragGestureValue in
            if self.emojiSelection.count > 0 {
                for i in 0..<self.emojiSelection.count {
                    self.document.moveEmoji(self.emojiSelection[i], by: finalDragGestureValue.translation / self.zoomScale)
                }
            } else {
                self.steadyStatePanOffset = self.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
            }
        }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0  {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            self.steadyStatePanOffset = .zero
            self.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        if self.emojiSelection.contains(matching: emoji) {
            location = CGPoint(x: location.x + gestureEmojiOffset.width, y: location.y + gestureEmojiOffset.height)
        }
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            self.document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) {string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
}
