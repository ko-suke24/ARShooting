//
//  ContentView.swift
//  ARShooting
//
//  Created by 佐藤航輔 on 2021/04/28.
//

import SwiftUI
import RealityKit

struct ARTitleView : View {
    @EnvironmentObject var gameInfo: GameInfo
    var body: some View {
        
        let arView = ARViewContainer().edgesIgnoringSafeArea(.all)
        let view = ZStack {
            
            arView
            
            VStack(spacing: 200) {
                if gameInfo.gameState == .menu {
                    Text("ARShooting")
                        .font(Font.custom("HelveticaNeue-Bold", size: 60.0))
                }
                
                Button(action: {
                    self.gameInfo.gameState = .placingContent
                }) {
                    if gameInfo.gameState == .menu {
                        Text("Game Start")
                    }
                }
            }
        }
        
        return view
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        // Load the "Box" scene from the "Experience" Reality File
        let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        arView.scene.anchors.append(boxAnchor)
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

#if DEBUG
struct ARTitleView_Previews : PreviewProvider {
    static var previews: some View {
        ARTitleView()
    }
}
#endif
