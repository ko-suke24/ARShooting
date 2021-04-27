//
//  GameInfo.swift
//  ARShooting
//
//  Created by 佐藤航輔 on 2021/04/28.
//

import SwiftUI

enum GameState {
    
    // ゲームメニューを表示しています
    case menu
    
    // 現実世界の平面を探しています
    case placingContent
    
    // ステージ1を表示しています
    case stage1
    
    // ステージ2を表示しています
    case stage2
    
    // ゲーム終了
    case endGame
}

final class GameInfo: ObservableObject {
    @Published var gameState: GameState = .menu
}
