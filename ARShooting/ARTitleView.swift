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
            
            // ステージ表示中
            if  gameInfo.gameState == .stage1 ||
                gameInfo.gameState == .stage2 {
                
                // ライフが残っている状態
                if gameInfo.selfLife > 0 {
                    
                    VStack {
                        
                        HStack {
                            
                            Spacer()
                            
                            // タイトル画面へ戻るボタン
                            Button(action: {
                                
                                self.gameInfo.gameState = .menu
                            }) {
                                
                                Text("Menu")
                                    .padding([.trailing, .top], 15)
                            }
                        }
                        
                        Spacer()
                        
                        HStack {
                            
                            // ライフ表示
                            Text("Life: " + String(gameInfo.selfLife))
                                .foregroundColor(.white)
                                .font(.system(size: 30))
                                .padding([.leading, .bottom], 15)
                            
                            Spacer()
                        }
                    }
                }
                else {
                    
                    VStack(spacing: 200) {
                        
                        // ゲームオーバー
                        Text("Game Over")
                            .foregroundColor(.white)
                            .font(.system(size: 60))
                        
                        // 全回復して、続けてプレイ
                        Button(action: {
                            
                            self.gameInfo.selfLife = 10
                        }) {
                            
                            Text("Continue")
                        }
                    }
                }
            }
            
            else if  gameInfo.gameState == .endGame {
                
                VStack(spacing: 200) {
                    
                    // ゲーム終了
                    Text("Congratulation")
                        .foregroundColor(.white)
                        .font(.system(size: 60))
                    
                    // タイトル画面へ戻る
                    Button(action: {
                        
                        self.gameInfo.gameState = .menu
                    }) {
                        
                        Text("Menu")
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
