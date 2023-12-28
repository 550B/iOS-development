//
//  GameScene.swift
//  Arknights
//
//  Created by apple on 12/24/23.
//

import SpriteKit

import GameplayKit

class GameScene: GameSceneHelper {
    
    // 状态机
    lazy var stateMachine: GKStateMachine = GKStateMachine(states: [GameSceneReadyState(scene: self), GameSceneActiveState(
        scene: self), GameSceneWinState(scene: self), GameSceneLoseState(scene: self)])
    
    // 更新时间状态
    var lastUpdateTimeInterval: TimeInterval = 0
    
    var entities = Set<GKEntity>()
    
    lazy var componentSystems: [GKComponentSystem] =
    {
        
        let animationSystem = GKComponentSystem(componentClass: AnimationComponent.self)
        
        let firingSystem = GKComponentSystem(componentClass: FiringComponent.self)
        
        let agentSystem = GKComponentSystem(componentClass: EnemyAgent.self)
        
        return [animationSystem, firingSystem, agentSystem]
        
    }()
    
    var towerSelectorNodes = [TowerSelectorNode]()
    
    var placingTower = false
    
    var placingTowerOnNode = SKNode()
    
    let obstacleGraph = GKObstacleGraph(obstacles: [], bufferRadius: 32)
    
    var waveManager: WaveManager!

    override func didMove(to view: SKView) {
        
        super.didMove(to: view)
        
        loadTowerSelectorNodes()
        
        let obstacleSpriteNodes = self["Sprites/Obstacle_*"] as! [SKSpriteNode]
        
        for obstacle in obstacleSpriteNodes {
            
            addObstacle(withNode: obstacle)
            
        }
        
        // 设置初始状态
        stateMachine.enter(GameSceneReadyState.self)
        
        startBackgroundMusic()
        
        let waves = [
            
            Wave(enemyCount: 5, enemyDelay: 3, enemyType: .ClassD),
            
            Wave(enemyCount: 8, enemyDelay: 2, enemyType: .ClassA),
            
            Wave(enemyCount: 10, enemyDelay: 2, enemyType: .ClassD),
            
            Wave(enemyCount: 25, enemyDelay: 1, enemyType: .ClassA),
            
            Wave(enemyCount: 1, enemyDelay: 1, enemyType: .ClassS)
            
        ]
        waveManager = WaveManager(waves: waves,
                                  newWaveHandler: { waveNum in
            
                                      self.waveLabel.text = "Wave \(waveNum)/\(waves.count)"
            
                                      self.run(SKAction.playSoundFileNamed("NewWave.mp3",
                                                                           waitForCompletion: false))
            
                                  },
                                  
                                  newEnemyHandler: { enemyType in
            
                                      self.addEnemy(enemyType: enemyType)
            
                                  })
        
    }

    override func update(_ currentTime: TimeInterval) {
        
        super.update(currentTime)
        
        // 未渲染就不uodate
        guard view != nil else {
            
            return
            
        }
        
        let deltaTime = currentTime - lastUpdateTimeInterval
        
        lastUpdateTimeInterval = currentTime
        
        // 暂停不更新
        if isPaused {
            
            return
            
        }
        
        // 更新状态机
        stateMachine.update(deltaTime: deltaTime)
        
        for componentSystem in componentSystems {
            
            componentSystem.update(deltaTime: deltaTime)
            
        }
        
    }

    override func didFinishUpdate() {
        
        let enemies: [EnemyEntity] = entities.compactMap { entity in
            
            if let enemy = entity as? EnemyEntity {
                
                return enemy
                
            }
            
            return nil
            
        }
        
        let towers: [TowerEntity] = entities.compactMap { entity in
            
            if let tower = entity as? TowerEntity {
                
                return tower
                
            }
            
            return nil
            
        }
        
        for tower in towers {
            
            let towerType = tower.towerType
            
            var target: EnemyEntity?
            
            for enemy in enemies.filter({
                
                (enemy: EnemyEntity) -> Bool in
                
                distanceBetween(nodeA: tower.spriteComponent.node,
                                nodeB: enemy.spriteComponent.node) < towerType.range
                
            }) {
                
                if let t = target {
                    
                    if towerType.hasSlowingEffect {
                        
                        if !enemy.hasBeenSlowed && t.hasBeenSlowed {
                            
                            target = enemy
                            
                        } else if enemy.hasBeenSlowed == t.hasBeenSlowed &&
                            enemy.spriteComponent.node.position.x > t.spriteComponent.node.position.x {
                            
                            target = enemy
                            
                        }
                        
                    } else if enemy.spriteComponent.node.position.x > t.spriteComponent.node.position.x {
                        
                        target = enemy
                        
                    }
                    
                } else {
                    
                    target = enemy
                    
                }
                
            }
            
            tower.firingComponent.currentTarget = target
            
        }
        
        for enemy in enemies {
            
            if enemy.healthComponent.health <= 0 {
                
                let win = waveManager.removeEnemyFromWave()
                
                if win {
                    
                    stateMachine.enter(GameSceneWinState.self)
                    
                }
                
                enemy.removeEntityFromScene(death: true)
                
                stopEnemyMoving(enemy: enemy)
                
                entities.remove(enemy)
                
                gold += enemy.enemyType.goldReward
                
                updateHUD()
                
            } else if enemy.spriteComponent.node.position.x > 1124 {
                
                waveManager.removeEnemyFromWave()
                
                baseLives -= enemy.enemyType.baseDamage
                
                updateHUD()
                
                self.run(baseDamageSoundAction)
                
                if baseLives <= 0 {
                    
                    stateMachine.enter(GameSceneLoseState.self)
                    
                }
                
                enemy.removeEntityFromScene(death: false)
                
                stopEnemyMoving(enemy: enemy)
                
                entities.remove(enemy)
                
            }
            
        }
        
        let ySortedEntities = Array<GKEntity>(entities).sorted { ent1, ent2 in
            
            let nodeA = ent1.component(ofType: SpriteComponent.self)!.node
            
            let nodeB = ent2.component(ofType: SpriteComponent.self)!.node
            
            return nodeA.position.y > nodeB.position.y
            
        }
        
        // 获取图层位置
        var zPosition = GameLayer.zDeltaForSprites
        
        for entity in ySortedEntities {
            
            // 获取精灵实体
            let spriteComponent = entity.component(ofType: SpriteComponent.self)
            
            // 获取精灵节点
            let node = spriteComponent!.node
            
            // 获得图层相对位置
            node.zPosition = zPosition
            
            // 设置图层绝对位置
            zPosition += GameLayer.zDeltaForSprites
            
        }
        
    }

    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        
        guard let touch = touches.first else {
            
            return
            
        }
        
        print("Touch: \(touch.location(in: self))")
        
        if let _ = stateMachine.currentState as? GameSceneReadyState {
            
            stateMachine.enter(GameSceneActiveState.self)
            
            return
            
        }
        
        let touchedNodes: [SKNode] = self.nodes(at: touch.location(in: self)).compactMap { node in
            
            if let nodeName = node.name,
               
               nodeName.hasPrefix("Tower_") {
                
                return node
                
            }
            
            return nil
            
        }
        
        if touchedNodes.count == 0 {
            
            hideTowerSelector()
            
            return
            
        }
        
        let touchedNode = touchedNodes[0]
        
        if placingTower {
            
            let touchedNodeName = touchedNode.name!
            
            if touchedNodeName == "Tower_Icon_WoodTower" {
                
                addTower(towerType: .Wood,
                         position: placingTowerOnNode.position)
                
            } else if touchedNodeName == "Tower_Icon_RockTower" {
                
                addTower(towerType: .Rock,
                         position: placingTowerOnNode.position)
                
            }
            
            hideTowerSelector()
            
        } else {
            
            placingTowerOnNode = touchedNode
            showTowerSelector(atPosition: touchedNode.position)
            
        }
        
    }

    func startFirstWave() {
        
        print("Start first wave!")
        
        waveManager.startNextWave()
        
        baseLabel.run(SKAction.fadeAlpha(to: 1.0, duration: 0.5))
        
        waveLabel.run(SKAction.fadeAlpha(to: 1.0, duration: 0.5))
        
        goldLabel.run(SKAction.fadeAlpha(to: 1.0, duration: 0.5))
        
    }

    func addEntity(entity: GKEntity) {
        
        entities.insert(entity)
        
        for componentSystem in self.componentSystems {
            
            componentSystem.addComponent(foundIn: entity)
            
        }
        
        if let spriteNode = entity.component(ofType: SpriteComponent.self)?.node {
            
            addNode(node: spriteNode,
                    toGameLayer: .Sprites)
            
            if let shadowNode = entity.component(ofType: ShadowComponent.self)?.node {
                
                addNode(node: shadowNode, toGameLayer: .Shadows)
                
                let xRange = SKRange(constantValue: shadowNode.position.x)
                
                let yRange = SKRange(constantValue: shadowNode.position.y)
                
                let constraint = SKConstraint.positionX(xRange, y: yRange)
                
                constraint.referenceNode = spriteNode
                
                shadowNode.constraints = [constraint]
                
            }
            
        }
        
    }

    func addEnemy(enemyType: EnemyType) {
        
        var startPosition = CGPoint(x: -200, y: 384)
        
        startPosition.y = startPosition.y + (CGFloat(random.nextInt() - 10) * 10)
        
        let endPosition = CGPoint(x: 1224, y: 384)
        
        let enemy = EnemyEntity(enemyType: enemyType)
        
        let eneNode = enemy.spriteComponent.node
        
        eneNode.position = startPosition
        
        setEnemyOnPath(enemy: enemy, toPoint: endPosition)
        
        addEntity(entity: enemy)
        
        enemy.animationComponent.requestedAnimationState = .Walk
        
    }

    func addTower(towerType: TowerType,
                  position: CGPoint) {
        
        if gold < towerType.cost {
            
            self.run(SKAction.playSoundFileNamed("NoBuildTower.mp3",
                                                 waitForCompletion: false))
            
            return
            
        }
        
        gold -= towerType.cost
        
        updateHUD()
        
        placingTowerOnNode.removeFromParent()
        
        self.run(SKAction.playSoundFileNamed("BuildTower.mp3",
                                             waitForCompletion: false))
        
        let towerEntity = TowerEntity(towerType: towerType)
        
        towerEntity.spriteComponent.node.position = position
        
        towerEntity.animationComponent.requestedAnimationState = .Idle
        
        addEntity(entity: towerEntity)
        
        addObstaclesToObstacleGraph(newObstacles: towerEntity.shadowComponent
                                                             .createObstaclesAtPosition(position: position))
        
        recalculateEnemyPaths()
        
    }

    func addObstacle(withNode node: SKSpriteNode) {
        
        // 储存障碍物位置
        let nodePosition = node.position
        
        // 从父节点移除
        node.removeFromParent()
        
        // 创建
        let obstacleEntity = ObstacleEntity(withNode: node)
        
        // 加入界面
        addEntity(entity: obstacleEntity)
        
        let obstacles = obstacleEntity.shadowComponent.createObstaclesAtPosition(position: nodePosition)
        
        addObstaclesToObstacleGraph(newObstacles: obstacles)
        
    }

    func setEnemyOnPath(enemy: EnemyEntity,
                           toPoint point: CGPoint) {
        
        let enemyNode = enemy.spriteComponent.node
        
        // 设置起始点
        let startNode = GKGraphNode2D(point: vector_float2(enemyNode.position))
        
        obstacleGraph.connectUsingObstacles(node: startNode)
        
        // 设置目标点
        let endNode = GKGraphNode2D(point: vector_float2(point))
        
        obstacleGraph.connectUsingObstacles(node: endNode)
        
        // 寻路
        let pathNodes = obstacleGraph.findPath(from: startNode,to: endNode) as! [GKGraphNode2D]
        
        // 开始移动
        obstacleGraph.remove([startNode, endNode])
        
        switch enemy.enemyType {
            
            case .ClassD, .ClassS:
            
                enemyNode.removeAction(forKey: "move")
            
                var pathActions = [SKAction]()
            
                var lastNodePosition = startNode.position
            
                for node2D in pathNodes {
                    
                    let nodePosition = CGPoint(node2D.position)
                    
                    let actionDuration = TimeInterval(lastNodePosition.distanceTo(point: node2D.position) / enemy.enemyType.speed)
                    
                    let pathNodeAction = SKAction.move(to: nodePosition,duration: actionDuration)
                    
                    pathActions.append(pathNodeAction)
                    
                    lastNodePosition = node2D.position
                    
                }
            
                enemyNode.run(SKAction.sequence(pathActions),
                                 withKey: "move")
            
            case .ClassA:
            
                if pathNodes.count > 1 {
                    
                    let enemyPath = GKPath(graphNodes: pathNodes, radius: 32.0)
                    
                    enemy.agent!.behavior = EnemyPathBehavior.pathBehavior(forAgent: enemy.agent!,
                                                                                 onPath: enemyPath,
                                                                                 avoidingObstacles: obstacleGraph.obstacles)
                    
                }
            
        }
        
    }

    func recalculateEnemyPaths() {
        
        // 计算敌人位置
        let endPosition = CGPoint(x: 1224, y: 384)
        
        let enemies: [EnemyEntity] = entities.compactMap { entity in
            
            if let enemy = entity as? EnemyEntity {
                
                if enemy.healthComponent.health <= 0 {
                    
                    return nil
                    
                }
                
                return enemy
                
            }
            
            return nil
            
        }
        
        for enemy in enemies {
            
            setEnemyOnPath(enemy: enemy,toPoint: endPosition)
            
        }
        
    }

    func stopEnemyMoving(enemy: EnemyEntity) {
        
        switch enemy.enemyType {
            
            case .ClassD, .ClassS:
            
                let enemyNode = enemy.spriteComponent.node
            
                enemyNode.removeAction(forKey: "move")
            
            case .ClassA:
            
                enemy.agent!.maxSpeed = 0.1
            
        }
        
    }

    func addObstaclesToObstacleGraph(newObstacles: [GKPolygonObstacle]) {
        
        obstacleGraph.addObstacles(newObstacles)
        
    }

    func loadTowerSelectorNodes() {
        
        // 加载可选择的防御塔
        let towerTypeCount = TowerType.allValues.count
        
        let towerSelectorNodePath: String = Bundle.main.path(forResource: "TowerSelector",
                                                             ofType: "sks")!
        
        let towerSelectorNodeScene = NSKeyedUnarchiver.unarchiveObject(withFile: towerSelectorNodePath) as! SKScene
        
        for t in 0..<towerTypeCount {
            
            let towerSelectorNode = (towerSelectorNodeScene.childNode(withName: "MainNode"))!.copy() as! TowerSelectorNode
            
            towerSelectorNode.setTower(towerType: TowerType.allValues[t],
                                       angle: ((2 * π) / CGFloat(towerTypeCount)) * CGFloat(t))
            
            towerSelectorNodes.append(towerSelectorNode)
            
        }
        
    }

    func showTowerSelector(atPosition position: CGPoint) {
        
        // 判断是否已经有防御塔
        if placingTower == true {
            
            return
            
        }
        
        placingTower = true
        
        // 选择防御塔
        self.run(SKAction.playSoundFileNamed("Menu.mp3",
                                             waitForCompletion: false))
        
        for towerSelectorNode in towerSelectorNodes {
            
            towerSelectorNode.position = position
            
            gameLayerNodes[.Hud]!.addChild(towerSelectorNode)
            
            towerSelectorNode.show()
            
        }
        
    }

    func hideTowerSelector() {
        
        if placingTower == false {
            
            return
            
        }
        
        placingTower = false
        
        self.run(SKAction.playSoundFileNamed("Menu.mp3", waitForCompletion: false))
        
        for towerSelectorNode in towerSelectorNodes {
            
            towerSelectorNode.hide {
                
                towerSelectorNode.removeFromParent()
                
            }
            
        }
        
    }
    
}

