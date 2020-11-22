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
    @State private var chosenPalette: String = ""
    
    init(document: EmojiArtDocument) {
        self.document = document
        _chosenPalette = State(wrappedValue: self.document.defaultPalette)
    }
    
    var body: some View {
        VStack {
            canvasPalette()
            documentCanvas()
            canvasControls()
        }
        .alert(isPresented: self.$confirmBackgroundPaste, content: {
            return Alert(
                title: Text("Paste Background"),
                message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?."),
                primaryButton: .default(Text("OK")) {
                    self.document.backgroundURL = UIPasteboard.general.url
                },
                secondaryButton: .cancel()
            )
        })
    }
    
    @State private var explainBackgroundPaste = false
    @State private var confirmBackgroundPaste = false
    
    @State private var emojiSelection = [EmojiArt.Emoji]()
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    @GestureState private var emojiZoomScale: CGFloat = 1.0
    
    private func toggleEmojiSelection(_ emoji: EmojiArt.Emoji) {
        if let i = emojiSelection.firstIndex(matching: emoji) {
            emojiSelection.remove(at: i)
        } else {
            emojiSelection.append(emoji)
        }
    }
    
    private var zoomScale: CGFloat {
        document.steadyStateZoomScale * gestureZoomScale
    }
    
    private func canvasPalette() -> some View {
        HStack {
            PaletteChooser(document: document, chosenPalette: $chosenPalette)
            ScrollView(.horizontal) {
                HStack {
                    ForEach(chosenPalette.map{ String($0) }, id: \.self) {emoji in
                        Text(emoji)
                            .font(Font.system(size: self.defaultEmojiSize))
                            .onDrag{ NSItemProvider(object: emoji as NSString) }
                    }
                }
            }
        }.padding(.horizontal)
    }
    
    private func canvasControls() -> some View {
        HStack {
            Button(action: {
                self.document.clearEmojis()
                self.document.backgroundURL = nil
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
    
    private func documentCanvas() -> some View  {
        GeometryReader { geometry in
            ZStack {
                Color.black.overlay(
                    OptionalImage(uiImage: self.document.backgroundImage)
                        .scaleEffect(self.zoomScale)
                        .offset(self.panOffset)
                )
                    // TODO: deal with delay on single tap ?
                    .gesture(self.doubleTapToZoom(in: geometry.size))
                    .gesture(self.tapToUnselect())
                
                if self.isLoading {
                    Image(systemName: "hourglass").imageScale(.large).spinning()
                } else {
                    ForEach(self.document.emojis) {emoji in
                        ZStack {
                            Text(emoji.text)
                                .border(Color.gray, width: self.emojiSelection.contains(matching: emoji) ? 2 : 0)
                                .font(animatableWithSize: emoji.fontSize*self.zoomScale*(self.emojiSelection.contains(matching: emoji) ? self.emojiZoomScale : 1.0))
                                .position(self.position(for: emoji, in: geometry.size))
                                .onTapGesture {
                                    self.toggleEmojiSelection(emoji)
                            }
                            .gesture(self.dragEmojiGesture(emoji))
                        }
                    }
                }
            }
            .clipped()
            .gesture(self.panGesture())
            .gesture(self.zoomGesture())
            .onReceive(self.document.$backgroundImage) {image in
                self.zoomToFit(image, in: geometry.size)
            }
            .navigationBarItems(
                trailing: Button(action: {
                    if let url = UIPasteboard.general.url, url != self.document.backgroundURL {
                        self.confirmBackgroundPaste = true
                    } else {
                        self.explainBackgroundPaste = true
                    }
                }, label: {
                    Image(systemName: "doc.on.clipboard").imageScale(.large)
                        .alert(isPresented: self.$explainBackgroundPaste, content: {
                            return Alert(
                                title: Text("Paste Background"),
                                message: Text("Copy URL of an image to the clipboard and touch this button to make it the background of your document."),
                                dismissButton: .default(Text("OK"))
                            )
                        })
                })
            )
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
                    return self.drop(providers: providers, at: location)
            }
        }.zIndex(-1)
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
                self.document.steadyStateZoomScale *= finalGestureScale
            }
        }
    }
    
    @GestureState private var gesturePanOffset: CGSize = .zero
    @GestureState private var gestureEmojiOffset: CGSize = .zero
    @GestureState private var singleMovedEmoji = MovingEmojiGesture()
    
    private var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    private var panOffset: CGSize {
        (document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func dragEmojiGesture(_ emoji: EmojiArt.Emoji) -> some Gesture {
        return DragGesture()
            .updating($singleMovedEmoji) { latestDragGestureValue, singleMovedEmoji, _ in
                singleMovedEmoji.emoji = emoji
                singleMovedEmoji.pan = latestDragGestureValue.translation
        }.onEnded{ finalDragGestureValue in
            self.document.moveEmoji(emoji, by: finalDragGestureValue.translation / self.zoomScale)
        }
        
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
                self.document.steadyStatePanOffset = self.document.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
            }
        }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.height > 0, size.width > 0  {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            self.document.steadyStatePanOffset = .zero
            self.document.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        if let selectedEmoji = singleMovedEmoji.emoji, selectedEmoji.id == emoji.id {
            location = CGPoint(x: location.x + singleMovedEmoji.pan.width, y: location.y + singleMovedEmoji.pan.height)
        }
        if self.emojiSelection.contains(matching: emoji) {
            location = CGPoint(x: location.x + gestureEmojiOffset.width, y: location.y + gestureEmojiOffset.height)
        }
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            self.document.backgroundURL = url
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) {string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
    
    struct MovingEmojiGesture {
        var emoji: EmojiArt.Emoji?
        var pan: CGSize = .zero
    }
}
