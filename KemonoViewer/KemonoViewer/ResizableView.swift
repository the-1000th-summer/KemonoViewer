//
//  ResizableView.swift
//  KemonoViewer
//
//  Created on 2025/7/3.
//

import SwiftUI

struct Transform {
    var offset: CGSize = .zero
}

func + (left: CGSize, right: CGSize) -> CGSize {
    CGSize(
        width: left.width + right.width,
        height: left.height + right.height)
}

func * (left: CGSize, right: CGFloat) -> CGSize {
    CGSize(
        width: left.width * right,
        height: left.height * right)
}

func *= (left: inout CGSize, right: Double) {
    left = CGSize(
        width: left.width * right,
        height: left.height * right)
}

func / (left: CGSize, right: CGFloat) -> CGSize {
    CGSize(
        width: left.width / right,
        height: left.height / right)
}

struct ResizableView: ViewModifier {
    @Binding var transform: Transform
    @State private var previousOffset: CGSize = .zero
    @State private var previousRotation: Angle = .zero
    @State private var scale: CGFloat = 1.0
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                transform.offset = value.translation + previousOffset
            }
            .onEnded { _ in
                previousOffset = transform.offset
            }
    }

//    var scaleGesture: some Gesture {
//        MagnificationGesture()
//            .onChanged { scale in
//                self.scale = scale
//            }
//            .onEnded { scale in
//                transform.size.width *= scale
//                transform.size.height *= scale
//                self.scale = 1.0
//            }
//    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .offset(transform.offset)
            .gesture(dragGesture)
//            .gesture(scaleGesture)
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                    if event.scrollingDeltaY > 0 && scale < 500 {
                        scale += 0.1
                    } else if event.scrollingDeltaY < 0 && scale > 0.19 {
                        scale -= 0.1
                    }
                    return event
                }
                previousOffset = transform.offset
            }
    }
}

extension View {
    func resizableView(transform: Binding<Transform>, viewScale: CGFloat = 1.0) -> some View {
        modifier(ResizableView(
            transform: transform,
        ))
    }
}

struct ResizableView_Previews: PreviewProvider {
    struct ResizableViewPreview: View {
        @State var transform = Transform()
        var body: some View {
            RoundedRectangle(cornerRadius: 30.0)
                .foregroundColor(Color.blue)
                .resizableView(transform: $transform)
        }
    }
    static var previews: some View {
        ResizableViewPreview()
    }
}
