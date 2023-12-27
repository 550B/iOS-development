//
//  Enemy.swift
//  Arknights
//
//  Created by apple on 12/24/23.
//

import Foundation

import UIKit

import GameplayKit

import SpriteKit

enum EnemyType: String {
    
    case ClassD = "ClassD"
    
    case ClassA = "ClassA"
    
    case ClassS = "ClassS"
    
    var health: Int {
        
        switch self {
            
            case .ClassD:
            
                return 60
            
            case .ClassA:
            
                return 40
            
            case .ClassS:
            
                return 1000
            
        }
        
    }
    
    var speed: Float {
        
        switch self {
            
            case .ClassD:
            
                return 100
            
            case .ClassA:
            
                return 150
            
            case .ClassS:
            
                return 50
            
        }
        
    }
    
    var baseDamage: Int {
        
        switch self {
            
            case .ClassD:
            
                return 2
            
            case .ClassA:
            
                return 1
            
            case .ClassS:
            
                return 5
            
        }
        
    }
    
    var goldReward: Int {
        
        switch self {
            
            case .ClassD:
            
                return 10
            
            case .ClassA:
            
                return 5
            
            case .ClassS:
            
                return 50
            
        }
        
    }
    
}

class EnemyAgent: GKAgent2D {
    
}

class EnemyEntity: GKEntity, GKAgentDelegate {
    
    let enemyType: EnemyType
    
    var spriteComponent: SpriteComponent!
    
    var shadowComponent: ShadowComponent!
    
    var animationComponent: AnimationComponent!
    
    var healthComponent: HealthComponent!
    
    var agent: EnemyAgent?
    
    var hasBeenSlowed = false

    init(enemyType: EnemyType) {
        
        self.enemyType = enemyType
        
        super.init()
        
        let size: CGSize
        
        switch enemyType {
            
            case .ClassD:
            
                size = CGSize(width: 203, height: 110)
            
            case .ClassA:
            
                size = CGSize(width: 142, height: 74)
            
            case .ClassS:
            
                size = CGSize(width: 400, height: 200)
            
        }
        
        let textureAtlas = SKTextureAtlas(named: enemyType.rawValue)
        
        let defaultTexture = textureAtlas.textureNamed("Walk__01.png")
        
        spriteComponent = SpriteComponent(entity: self,texture: defaultTexture,size: size)
        
        addComponent(spriteComponent)
        
        let shadowSize = CGSize(width: size.width, height: size.height * 0.3)
        
        shadowComponent = ShadowComponent(size: shadowSize,
                                          offset: CGPoint(x: 0.0, y: -size.height / 2 + shadowSize.height / 2))
        
        addComponent(shadowComponent)
        
        animationComponent = AnimationComponent(node: spriteComponent.node,
                                                textureSize: size, animations: loadAnimations())
        
        addComponent(animationComponent)
        
        healthComponent = HealthComponent(parentNode: spriteComponent.node,
                                          barWidth: size.width,
                                          barOffset: size.height,
                                          health: enemyType.health)
        
        addComponent(healthComponent)
        
        if enemyType == .ClassA {
            
            agent = EnemyAgent()
            
            agent!.delegate = self
            
            agent!.maxSpeed = enemyType.speed
            
            agent!.maxAcceleration = 200.0
            
            agent!.mass = 0.1
            
            agent!.radius = Float(size.width * 0.5)
            
            agent!.behavior = GKBehavior()
            
            addComponent(agent!)
            
        }
        
    }

    required init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) 初始化失败")
        
    }

    func agentWillUpdate(_ agent: GKAgent) {
        
        self.agent!.position = simd_float2(x: Float(spriteComponent.node.position.x),
                                           y: Float(spriteComponent.node.position.y))
        
    }

    func agentDidUpdate(_ agent: GKAgent) {
        
        let agentPosition = CGPoint(self.agent!.position)
        
        spriteComponent.node.position = CGPoint(x: agentPosition.x,
                                                y: agentPosition.y)
        
    }

    func removeEntityFromScene(death: Bool) {
        
        if death {
            
            // 播放死亡动画
            animationComponent.requestedAnimationState = .Dead
            
            let soundAction = SKAction.playSoundFileNamed("\(enemyType.rawValue)Dead.mp3",
                                                          waitForCompletion: false)
            
            let waitAction = SKAction.wait(forDuration: 2.0)
            
            let removeAction = SKAction.run({ () -> Void in
                self.spriteComponent.node.removeFromParent()
                self.shadowComponent.node.removeFromParent()
            })
            
            spriteComponent.node.run(SKAction.sequence([soundAction, waitAction, removeAction]))
            
        } else {
            
            spriteComponent.node.removeFromParent()
            
            shadowComponent.node.removeFromParent()
            
        }
        
    }

    func slowed(slowFactor: Float) {
        
        hasBeenSlowed = true
        
        animationComponent.node.color = SKColor.cyan
        
        animationComponent.node.colorBlendFactor = 1.0
        
        switch enemyType {
            
            case .ClassD, .ClassS:
            
                spriteComponent.node.speed = CGFloat(slowFactor)
            
            case .ClassA:
            
                agent!.maxSpeed = enemyType.speed * slowFactor
            
        }
        
    }

    func loadAnimations() -> [AnimationState: Animation] {
        
        let textureAtlas = SKTextureAtlas(named: enemyType.rawValue)
        
        var animations = [AnimationState: Animation]()
        
        animations[.Walk] = AnimationComponent.animationFromAtlas(atlas: textureAtlas,
                                                                  withImageIdentifier: "Walk",
                                                                  forAnimationState: .Walk)
        
        animations[.Hit] = AnimationComponent.animationFromAtlas(atlas: textureAtlas,
                                                                 withImageIdentifier: "Hurt",
                                                                 forAnimationState: .Hit,
                                                                 repeatTexturesForever: false)
        
        animations[.Dead] = AnimationComponent.animationFromAtlas(atlas: textureAtlas,
                                                                  withImageIdentifier: "Dead",
                                                                  forAnimationState: .Dead,
                                                                  repeatTexturesForever: false)
        
        return animations
        
    }
    
}

