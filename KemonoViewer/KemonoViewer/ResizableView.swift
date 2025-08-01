//
//  ResizableView.swift
//  KemonoViewer
//
//  Created on 2025/7/3.
//

import SwiftUI

struct Transform {
    var previousOffset: CGSize = .zero
    var offset: CGSize = .zero
    var scaleInPercent: Int = 100
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
    
//    @State private var previousOffset: CGSize = .zero
    @Binding var transform: Transform
    
    @ObservedObject var messageManager: StatusMessageManager
    @State private var scaleEventMonitor: Any?
    @State private var dragEventMonitor: Any?
    
    @Binding var insideView: Bool
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                transform.offset = value.translation + transform.previousOffset
            }
            .onEnded { _ in
                transform.previousOffset = transform.offset
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
            .scaleEffect(CGFloat(transform.scaleInPercent) / 100)
            .offset(transform.offset)
//            .gesture(dragGesture)
//            .gesture(scaleGesture)
//            .onHover(perform: { hovering in
//                insideCircle = hovering
//            })
            .onAppear {
                
                transform = Transform()
//                print("add scale event")
                scaleEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
//                    print("scale event")
                    if insideView {
//                        print("inside, scroll")
                        if event.scrollingDeltaY > 0 && transform.scaleInPercent < 500 {
                            transform.scaleInPercent += 10
                            messageManager.show(message: "\(transform.scaleInPercent)%")
                        } else if event.scrollingDeltaY < 0 && transform.scaleInPercent > 10 {
                            transform.scaleInPercent -= 10
                            messageManager.show(message: "\(transform.scaleInPercent)%")
                        }
                    }
                    return event
                }
                
                dragEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { event in
                    if insideView {
                        transform.offset = transform.offset + CGSize(width: event.deltaX, height: event.deltaY)
                    }
                    return event
                }
            }
            .onDisappear {
                if let scaleEventMonitor {
                    NSEvent.removeMonitor(scaleEventMonitor)
                }
                if let dragEventMonitor {
                    NSEvent.removeMonitor(dragEventMonitor)
                }
                scaleEventMonitor = nil
                dragEventMonitor = nil
            }
    }
}

extension View {
    func resizableView(insideView: Binding<Bool>, transform: Binding<Transform>, messageManager: StatusMessageManager) -> some View {
        return modifier(ResizableView(
            transform: transform,
            messageManager: messageManager,
            insideView: insideView
        ))
    }
}

struct ResizableView_Previews: PreviewProvider {
    struct ResizableViewPreview: View {
        @State var transform = Transform()
        var body: some View {
            RoundedRectangle(cornerRadius: 30.0)
                .foregroundColor(Color.blue)
                .resizableView(insideView: .constant(false), transform: $transform, messageManager: StatusMessageManager())
        }
    }
    static var previews: some View {
        ResizableViewPreview()
    }
}
