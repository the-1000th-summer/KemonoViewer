//
//  ScrollToTopBottomButton.swift
//  KemonoViewer
//
//  Created on 2025/7/22.
//

import SwiftUI

struct MyCustomButton: View {
    let action: () -> Void
    let imageSystemName: String
    
    var body: some View {
        Button(action: action) {
            Image(systemName: imageSystemName)
                .font(.system(size: 25))
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 50, height: 50)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ScrollToTopBottomButton: View {
    @Binding var scrollToTop: Bool
    @Binding var scrollToBottom: Bool
    
    var body: some View {
        HStack {
            MyCustomButton(
                action: {scrollToTop.toggle()},
                imageSystemName: "arrow.up"
            )
            .padding()
            
            MyCustomButton(
                action: {scrollToBottom.toggle()},
                imageSystemName: "arrow.down"
            )
            .padding()
        }
        .hoverVisible()
        .padding(.trailing, 25)
        .padding(.bottom, 20)
    }
}

#Preview {
    ScrollToTopBottomButton(scrollToTop: .constant(true), scrollToBottom: .constant(false))
}
