//
//  ARShootingView.swift
//  ARShooting
//
//  Created by 佐藤航輔 on 2021/04/28.
//

import SwiftUI
import ARKit
import RealityKit
import Combine

struct EntityName {
    
    static let bulletAnchor = "BulletAnchor"
    static let bullet = "Bullet"
  
    // 弾丸
    static let selfBullet = "SelfBullet"
    static let enemyBullet = "EnemyBullet"
    
    static let cameraBox = "CameraBox"
    
}

struct ModelInfo {
    var name: String = ""
    var life: Int = 0
}

struct StageModel {
    
    // ステージ1
    var rocket1 = ModelInfo(name: "Rocket1", life: 10)
    
    func stage1() -> Array<ModelInfo> {
        return [rocket1]
    }
}

class ARShootingView: UIView, ARSessionDelegate {
    
    // ARView
    let arView = ARView(frame: UIScreen.main.bounds)
    
    // コーチングオーバーレイビュー
    let coachingOverlayView = ARCoachingOverlayView(frame: UIScreen.main.bounds)
    
    // ステージ
    var gameAnchor = try! GameStages.loadStage1()
    
    // ゲーム情報
    var gameInfo: GameInfo
    
    // ゲーム情報を受け取るタスク
    var gameInfoTask: AnyCancellable?
    
    var stageModel = StageModel()
    
    var enemyBulletTimer: Timer?
    
    var collisionEventStreams = [AnyCancellable]()

    var startFlg: Bool = false

    // 初期化
    init(frame frameRect: CGRect, gameInfo: GameInfo) {
        
        // ゲーム情報の受け取り
        self.gameInfo = gameInfo
        
        // 親クラスの初期化
        super.init(frame: frameRect)
        
        arView.session.delegate = self
        
        // ARViewの追加
        addSubview(arView)
        
        // ゲーム情報の受け取りタスク
        self.gameInfoTask = gameInfo.$gameState.receive(on: DispatchQueue.main).sink { (value) in

            if value == .placingContent {
                
                if self.startFlg == false {
                    
                   self.setupConfiguration()
                     
                   self.addCoachingOverlayView()
                    
                }
                else {
                    gameInfo.gameState = .stage1
                }
            }
        }
    }
    
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- Configuration

    // コンフィグ設定
    func setupConfiguration() {

        // 床の平面を探す
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config, options: [])
    }
    
    //MARK:- Game
    
    // ゲーム開始
    func startGame() {
        
        // ゲームアンカー追加
        arView.scene.addAnchor(gameAnchor)
        
        setupGestureRecognizers()
        
        // ステージ1に移行
        gameInfo.gameState = .stage1
      
        // 平面検出の停止
        arView.session.run(ARWorldTrackingConfiguration())
        
        startFlg = true
        
        // 3秒に1回敵の弾丸が発射するタイマー
        enemyBulletTimer = Timer.scheduledTimer(timeInterval: 3,
                                                target: self,
                                                selector: #selector(stageBulletShot),
                                                userInfo: nil,
                                                repeats: true)
        
        // カメラの当たり判定
        let camera = CameraBox(entityName: EntityName.cameraBox)
        let cameraAnchor = AnchorEntity(.camera)
        cameraAnchor.addChild(camera.hitBox)
        arView.scene.addAnchor(cameraAnchor)

        // カメラの10cm後ろに配置します
        camera.hitBox!.transform.translation = [0, 0, 0.1]
        
        // 衝突イベント
        arView.scene.subscribe(to: CollisionEvents.Began.self) { event in
            
            // 敵からのダメージ判定
            if  event.entityA.name == EntityName.enemyBullet &&
                event.entityB.name == EntityName.cameraBox {
                
                self.gameInfo.selfLife -= 1
            }
            
            // ステージ１
            if self.gameInfo.gameState == .stage1 {
                
                self.stage1Damage(entityAName: event.entityA.name, entityBName: event.entityB.name)
            }
            
        }.store(in: &collisionEventStreams)
    }
    
    func stage1Damage(entityAName: String, entityBName: String) {
        
        // 敵へのダメージ判定
        if  entityAName == EntityName.selfBullet &&
            entityBName == stageModel.rocket1.name {
            
            // ステージ2へ移行
            if  stageModel.rocket1.life == 0 &&
                gameInfo.selfLife > 0 {
                
                gameInfo.gameState = .stage2
                
                // ステージ変更の通知
                gameAnchor.notifications.changeStage2.post()
            }
            // ダメージ判定
            else {
                
                stageModel.rocket1.life -= 1
                
                // サウンド再生と表示アクションの通知
                gameAnchor.notifications.hitRocket1.post()
            }
            
        }
    }
        
        // 敵の弾丸が定期的に発射されます
        @objc func stageBulletShot() {
            
            var stageInfo: Array<ModelInfo> = []
            
            // ステージ1のモデル情報を取得
            if gameInfo.gameState == .stage1 {
                stageInfo = stageModel.stage1()
            }
                
            // 3Dコンテンツから弾丸発射
            for model: ModelInfo in stageInfo {
                
                enemyBulletShot(name: model.name)
            }
        }
        
        func enemyBulletShot(name: String) {
            
            // ロケットのEntityを取得
            let entity = gameAnchor.findEntity(named: name)
            
            guard let rocketEntity = entity else {
                return
            }
          
            // カメラの位置を取得
            let cameraPos = gameAnchor.convert(transform: arView.cameraTransform, from: nil)

            // 弾丸を生成
            let enemy = BulletSphere(startPosition: rocketEntity.position, entityName: EntityName.enemyBullet)
            
            // 弾丸を追加
            gameAnchor.addChild(enemy.bullet)
            
            // ロケットの位置からカメラの位置まで移動させます
            let animeMove = enemy.bullet.move(to: cameraPos,
                                              relativeTo: gameAnchor,
                                              duration: 2,
                                              timingFunction: AnimationTimingFunction.linear)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                animeMove.entity?.removeFromParent()
            }
        }
    
    //MARK:- GestureRecognizers
    
    // ジェスチャー設定
    func setupGestureRecognizers() {
        
        // タップして撃つ
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(addBulletAnchor(recognizer:)))
        
        tapRecognizer.numberOfTouchesRequired = 1
        
        // シーンにジェスチャー追加
        addGestureRecognizer(tapRecognizer)
    }
    
    // 弾丸のARAnchor追加
    @objc func addBulletAnchor(recognizer: UITapGestureRecognizer){
        
        // sessionにARAnchorを追加する (ARAnchorはARKitのクラス)
        let bulletAnchor = ARAnchor(name: EntityName.bulletAnchor, transform: arView.cameraTransform.matrix)
        arView.session.add(anchor: bulletAnchor)
        
    }
    
    // 弾丸を発射します
    func bulletShot(named entityName: String, for anchor: ARAnchor) {
        
        // Bulletを取得する
        let bulletEntity = try! ModelEntity.load(named: entityName)
        
        // ARAnchorをAnchorEntityに変換します
        let anchorEntity = AnchorEntity(anchor: anchor)
        
        anchorEntity.addChild(bulletEntity)
        arView.scene.addAnchor(anchorEntity)
        
        // 弾丸が0.4秒で端に到達するので、プラス0.1秒後に消します
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.arView.scene.removeAnchor(anchorEntity)
        }

    }
    
    // 弾丸を発射します(ソースコードバージョン)
    func bulletShotCode(named entityName: String, for anchor: ARAnchor) {
        
        // ARAnchorをAnchorEntityに変換します
        let anchorEntity = AnchorEntity(anchor: anchor)
        
        // 自分自身の弾丸を生成
        let bulletEntity = BulletSphere(startPosition: anchorEntity.position, entityName: EntityName.selfBullet)
                
        // アンカーに弾丸を追加
        anchorEntity.addChild(bulletEntity.bullet)
        
        // シーンにアンカーを追加
        arView.scene.addAnchor(anchorEntity)
        
        // カメラ座標の3m前
        let infrontOfCamera = SIMD3<Float>(x: 0, y: 0, z: -3)
        
        // カメラ座標 -> アンカー座標
        let bulletPos = anchorEntity.convert(position: infrontOfCamera, to: gameAnchor)
        
        // 3D座標(xyz)を4×4行列に変換
        let movePos = float4x4.init(translation: bulletPos)
        
        // 弾丸を移動
        let animeMove = bulletEntity.bullet.move(to: movePos,
                                                 relativeTo: gameAnchor,
                                                 duration: 0.4,
                                                 timingFunction: AnimationTimingFunction.linear)

        // 発射時にサウンド再生
        let hitSound = try! AudioFileResource.load(named: "ShootSound.wav")
        bulletEntity.bullet.playAudio(hitSound)
      
        // 弾丸が0.4秒で端に到達するので、プラス0.1秒後に消します
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animeMove.entity?.removeFromParent()
            self.arView.scene.removeAnchor(anchorEntity)
        }

    }
    
    //MARK:- ARSessionDelegate
    
    // ARAnchorが追加されると呼ばれます
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        
        for anchor in anchors {
            
            if let anchorName = anchor.name, anchorName == EntityName.bulletAnchor {
                bulletShotCode(named: EntityName.bullet, for: anchor)
            }
        }
    }
}

extension float4x4 {

    init(translation vector: SIMD3<Float>) {
        self.init(.init(1, 0, 0, 0),
                  .init(0, 1, 0, 0),
                  .init(0, 0, 1, 0),
                  .init(vector.x, vector.y, vector.z, 1))
    }
}
