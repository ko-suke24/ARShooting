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
        
        let arView = ARViewContainer(gameInfo: gameInfo).edgesIgnoringSafeArea(.all)
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
    
    var gameInfo: GameInfo
    
    func makeUIView(context: Context) -> UIView {
        
        return ARShootingView(frame: .zero, gameInfo: gameInfo)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
}

#if DEBUG
struct ARTitleView_Previews : PreviewProvider {
    static var previews: some View {
        ARTitleView()
    }
}
#endif
