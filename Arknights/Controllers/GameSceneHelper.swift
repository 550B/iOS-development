//
//  GameSceneHelper.swift
//  Arknights
//
//  Created by apple on 12/24/23.
//

import SpriteKit

import GameKit

import AVFoundation

enum GameLayer: CGFloat {
    
    // 将敌人、防御塔、障碍物放到不同的zIndex
    static let zDeltaForSprites: CGFloat = 10
    
    // 将game layer分层
    case Background = -100
    
    case Shadows = -50
    
    case Sprites = 0
    
    case Hud = 1000
    
    case Overlay = 1100
    
    // 定义每一层layer的名字
    var nodeName: String {
        
        switch self {
            
            case .Background:
            
                return "Background"
            
            case .Shadows:
            
                return "Shadows"
            
            case .Sprites:
            
                return "Sprites"
            
            case .Hud:
            
                return "Hud"
            
            case .Overlay:
            
                return "Overlay"
            
        }
        
    }
    
    static var allLayers = [Background, Shadows, Sprites, Hud, Overlay]
    
}

class GameSceneHelper: SKScene {
    
    // 游戏层node
    var gameLayerNodes = [GameLayer: SKNode]()
    
    // 用于产生随机分布的敌人
    let random = GKRandomDistribution.d20()
    
    // 视图大小
    var viewSize: CGSize {
        
        return self.view!.frame.size
        
    }
    
    var sceneScale: CGFloat {
        
        let minScale = min(viewSize.width / self.size.width,
                           viewSize.height / self.size.height)
        
        let maxScale = max(viewSize.width / self.size.width,
                           viewSize.height / self.size.height)
        
        return sqrt(minScale / maxScale)
        
    }
    
    // HUD
    var baseLabel: SKLabelNode!
    
    var waveLabel: SKLabelNode!
    
    var goldLabel: SKLabelNode!
    
    // 游戏状态
    var readyScreen: ReadyNode!
    
    var winScreen: WinNode!
    
    var loseScreen: LoseNode!
    
    // 血量
    var baseLives = 5
    
    // 初始金币
    var gold = 75
    
    // Background music
    var musicPlayer: AVAudioPlayer!
    
    // 播放音频
    let baseDamageSoundAction = SKAction.playSoundFileNamed("LifeLost.mp3",
                                                            waitForCompletion: false)
    
    let winSoundAction = SKAction.playSoundFileNamed("YouWin.mp3",
                                                     waitForCompletion: false)
    
    let loseSoundAction = SKAction.playSoundFileNamed("YouLose.mp3",
                                                      waitForCompletion: false)

    override func didMove(to view: SKView) {
        
        super.didMove(to: view)
        
        // 不需要重力
        physicsWorld.gravity = CGVector.zero
        
        // 读取layer
        loadGameLayers()
        
        // 生成布局
        layoutHUD()
        
        // 读取游戏的ready/win/lose状态
        loadStateScreens()
        
        showReady(show: true)
        
    }

    func startBackgroundMusic() {
        
        // 启动背景音乐
        let musicFileURL = Bundle.main.url(forResource: "BackgroundMusic",
                                           withExtension: "mp3")

        do {

            musicPlayer = try AVAudioPlayer(contentsOf: musicFileURL!)
            
//            musicPlayer = try AVAudioPlayer(data: BackgroundMusic)

            musicPlayer.prepareToPlay()

            musicPlayer.volume = 0.5

            musicPlayer.numberOfLoops = -1

            musicPlayer.play()

        }
        
        catch {
            
            fatalError("Error loading \(String(describing: musicFileURL)): \(error)")
            
        }
        
    }

    func loadGameLayers() {
        
        for gameLayer in GameLayer.allLayers {
            
            // 读取scence
            let foundNodes = self[gameLayer.nodeName]
            
            let layerNode = foundNodes.first!
            
            // 设置zIndex
            layerNode.zPosition = gameLayer.rawValue
            
            // 存储node
            gameLayerNodes[gameLayer] = layerNode
            
        }
        
    }

    // 将选中的HUD进行布局
    func layoutHUD() {
        
        let hudNode = gameLayerNodes[.Hud]!
        
        // 血条
        if let baseLabel = hudNode.childNode(withName: "BaseLabel") as? SKLabelNode {
            
            self.baseLabel = baseLabel
            
            self.baseLabel.position = CGPoint(x: baseLabel.position.x,
                                              y: (self.size.height - baseLabel.position.y) * sceneScale)
            
            self.baseLabel.alpha = 0
            
        }
        
        // 敌人波数
        if let waveLabel = hudNode.childNode(withName: "WaveLabel") as? SKLabelNode {
            
            self.waveLabel = waveLabel
            
            self.waveLabel.position = CGPoint(x: waveLabel.position.x,
                                              y: (self.size.height - waveLabel.position.y) * sceneScale)
            
            self.waveLabel.alpha = 0
            
        }
        
        // 金币数
        if let goldLabel = hudNode.childNode(withName: "GoldLabel") as? SKLabelNode {
            
            self.goldLabel = goldLabel
            
            self.goldLabel.position = CGPoint(x: goldLabel.position.x,
                                              y: (self.size.height - goldLabel.position.y) * sceneScale)
            
            self.goldLabel.alpha = 0
            
        }
        
    }

    // 更新血条金币
    func updateHUD() {
        
        baseLabel.text = "Lives: \(max(0, baseLives))"
        
        goldLabel.text = "Gold: \(gold)"
        
    }

    // 读取 ready win lose 界面
    func loadStateScreens() {
        
        // Ready
        let readyScenePath: String = Bundle.main.path(forResource: "ReadyScene", ofType: "sks")!
        
        let readyScene = NSKeyedUnarchiver.unarchiveObject(withFile: readyScenePath) as! SKScene
        
        if let readyScreen = (readyScene.childNode(withName: "MainNode"))!.copy() as? ReadyNode {
            
            self.readyScreen = readyScreen
            
        }
        
        // Win
        let winScenePath: String = Bundle.main.path(forResource: "WinScene", ofType: "sks")!
        
        let winScene = NSKeyedUnarchiver.unarchiveObject(withFile: winScenePath) as! SKScene
        
        if let winScreen = (winScene.childNode(withName: "MainNode"))!.copy() as? WinNode {
            
            self.winScreen = winScreen
            
        }
        
        // Lose
        let loseScenePath: String = Bundle.main.path(forResource: "LoseScene", ofType: "sks")!
        
        let loseScene = NSKeyedUnarchiver.unarchiveObject(withFile: loseScenePath) as! SKScene
        
        if let loseScreen = (loseScene.childNode(withName: "MainNode"))!.copy() as? LoseNode {
            
            self.loseScreen = loseScreen
            
        }
        
    }

    // 点击开始 ，隐藏ready界面
    func showReady(show: Bool) {
        
        if show {
            
            updateHUD()
            
            addNode(node: readyScreen,
                    toGameLayer: .Overlay)
            
            readyScreen.show()
            
        } else {
            
            readyScreen.hide()
            
        }
        
    }
    
    func backToReady(){
        
        readyScreen.alpha = 0.0
        
        updateHUD()
        
        addNode(node: readyScreen, toGameLayer: .Overlay)
        
        readyScreen.show()
        
    }

    func showWin() {
        
        // 播放结束音乐
        self.run(winSoundAction)
        
        // 停止之前的背景音乐
        musicPlayer.pause()
        
        // 显示win界面
        winScreen.alpha = 0.0
        
        addNode(node: winScreen, toGameLayer: .Overlay)
        
        winScreen.run(SKAction.sequence([SKAction.fadeAlpha(to: 1.0, duration: 1.0), SKAction.run({ () -> Void in
            
            // 在0.1秒内显示
            self.speed = 0.1
            
        })]))
        
        winScreen.show()
        
    }

    func showLose() {
        
        // 播放失败音乐
        self.run(loseSoundAction)
        
        // 停止背景音乐
        musicPlayer.pause()
        
        // 显示lose界面
        loseScreen.alpha = 0.0
        
        addNode(node: loseScreen, toGameLayer: .Overlay)
        
        loseScreen.run(SKAction.sequence([SKAction.fadeAlpha(to: 1.0, duration: 1.0), SKAction.run({ () -> Void in
            
             // 在0.1秒内显示
            self.speed = 0.1
            
        })]))
        
        loseScreen.show()
        
    }

    func addNode(node: SKNode,
                 toGameLayer: GameLayer) {
        
        gameLayerNodes[toGameLayer]!.addChild(node)
        
    }
}

