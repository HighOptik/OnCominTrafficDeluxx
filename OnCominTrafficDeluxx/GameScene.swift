import SpriteKit

enum GameState : Int {
    case waitingForTap = 0
    case waitingForCrash = 1
    case playing = 2
    case gameOver = 3
}

enum PlayerState : Int {
    case idle = 0
    case boost = 1
    case crash = 2
    case dead = 3
}

struct PhysicsCategories {
    static let None: UInt32                = 0
    static let Player: UInt32              = 0b1
    static let Coin: UInt32                = 0b10
    static let Traffic: UInt32             = 0b100
    static let Powerup: UInt32             = 0b1000
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    var gameState = GameState.waitingForTap
    var playerState = PlayerState.idle
    var bgNode: SKNode!
    var fgNode: SKNode!
    var bgOverlayNode: SKNode!
    var bgOverlayHeight:CGFloat!
    var player: SKSpriteNode!
    //var car1: SKSpriteNode!
    var lastOverlayPos = CGPoint.zero
    var lastOverlayHeight: CGFloat=0.0
    var levelPositionY: CGFloat=0.0
    let cameraNode = SKCameraNode()
    var lava: SKSpriteNode!
    
    var playableRect: CGRect!
    var playableMargin: CGFloat = 0.0
    var playableHeight: CGFloat = 0.0
    var maxAspectRatio: CGFloat = 0.0
    //var playable: CGRect!
    

    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
        print("Width: \(playableRect.width)")
        print("Height: \(playableRect.height)")
    }
    
    
    override func didMove(to view: SKView) {
        maxAspectRatio = 16.0/9.0
        playableHeight = size.width / maxAspectRatio
        playableMargin = (size.height-playableHeight)/2.0
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)
        SetupNodes()
        SetupTransition()
        let scale = SKAction.scale(to:1.0, duration: 0.5)
        fgNode.childNode(withName: "Ready")!.run(scale)
        physicsWorld.contactDelegate = self
        
        debugDrawPlayableArea()
        
        SetUpCoreMotion()
        
        
        
    }

    
    func sceneCropAmount() -> CGFloat {
        guard let view = view else {
            return 0
        }
        let scale = view.bounds.size.height / size.height
        let scaledWidth = size.width * scale
        let scaledOverlap = scaledWidth - view.bounds.size.width
        return scaledOverlap / scale
    }


    func SetUpCoreMotion() -> CGFloat {
        guard let view = view else {
            return 0
        }
        let scale = view.bounds.size.height / size.height
        let scaledWidth = size.width * scale
        let scaledOverlap = scaledWidth - view.bounds.size.width
        return scaledOverlap/scale
    }
    
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        if gameState == .waitingForTap {
            StartGame()
        }
    }
    
    func SetupNodes(){
        let worldNode = childNode(withName: "World")!
        bgNode = worldNode.childNode(withName: "Background")!
        bgOverlayNode = bgNode.childNode(withName: "Overlay")!.copy() as! SKNode
        bgOverlayHeight = bgOverlayNode.calculateAccumulatedFrame().height
        fgNode = worldNode.childNode(withName: "Foreground")!
        player = fgNode.childNode(withName: "Player") as! SKSpriteNode
        addChild(cameraNode)
        camera = cameraNode
//        lava = fgNode.childNode(withName: "Cops") as! SKSpriteNode
    }
    
    func updateCamera(){
        let cameraTarget = convert(player.position,from: fgNode)
        let targetPositionY = cameraTarget.y - (size.height * -0.45)
        let diff = targetPositionY - camera!.position.y
        let cameraLagFactor: CGFloat = 0.1
        let lagDiff = diff * cameraLagFactor
        let newCameraPositionY = camera!.position.y + lagDiff
        camera!.position.y = newCameraPositionY
    
    }
    
    
    func StartGame(){
        gameState = .playing
        let scale = SKAction.scale(to: 0, duration:  0.4)
        fgNode.childNode(withName: "Title")!.run(scale)
        fgNode.childNode(withName: "Ready")!.run(
        SKAction.sequence(
            [SKAction.wait(forDuration: 0.2), scale]))
        player.physicsBody!.isDynamic = true
        setPlayerSetVelocity(250)
        
       
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
                self?.spawnCar()
                },
                               SKAction.wait(forDuration: 1.0)])))
        
    }
    
    func SetupTransition(){
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width * 3.0)
        player.physicsBody!.isDynamic = false
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.allowsRotation = false
        player.physicsBody!.categoryBitMask = 0;
        player.physicsBody!.collisionBitMask = 0;
    }
    
    func setPlayerSetVelocity(_ amount: CGFloat){
        let gain: CGFloat = 1.5
        player.physicsBody!.velocity.dy = max(player.physicsBody!.velocity.dy, amount * gain)
    }

    func loadForegroundNode(_ fileName: String) -> SKSpriteNode {
        
        let overlayScene = SKScene(fileNamed: fileName)!
        let overlayTemplate = overlayScene.childNode(withName: "Overlay")
        return overlayTemplate as! SKSpriteNode
    }
    
    func createForeground(_ overlayTemplate: SKSpriteNode, flipX: Bool){
        
        let foregroundOverlay = overlayTemplate.copy() as! SKSpriteNode
        lastOverlayPos.y = lastOverlayPos.y + (lastOverlayHeight + (foregroundOverlay.size.height / 2.0))
        lastOverlayHeight = foregroundOverlay.size.height / 2
        foregroundOverlay.position = lastOverlayPos
        if (flipX == true)
        {
            foregroundOverlay.xScale = -1.0
        }
        fgNode.addChild(foregroundOverlay)
    }
    
    func createBackground() {
        
        let backgroundOverlay = bgOverlayNode.copy() as! SKNode
        backgroundOverlay.position = CGPoint (x:0.0, y: levelPositionY)
        bgNode.addChild(backgroundOverlay)
        levelPositionY += bgOverlayHeight
    }
    
    func didBegin(_ contact: SKPhysicsContact)  {
        let other = contact.bodyA.categoryBitMask ==
            PhysicsCategories.Player ? contact.bodyB : contact.bodyA
        
        switch other.categoryBitMask {
        case PhysicsCategories.Coin:
            if let coin = other.node as? SKSpriteNode {
                coin.removeFromParent()
                setPlayerSetVelocity(50)
            }
        case PhysicsCategories.Powerup:
            if let PU = other.node as? SKSpriteNode {
                PU.removeFromParent()
                setPlayerSetVelocity(50)
            }

        default:
            break
        }
    }

    ///SPAWN ENEMY - ERICK HOBBS
    func spawnCar() {
        let car1 = SKSpriteNode(imageNamed: "Car1")
        car1.name = "Car1"
        car1.position = CGPoint(x: CGFloat.random (
            min: playableRect.minX + car1.size.width/2,
            max: playableRect.maxX - car1.size.width/2),
                                y: size.height + car1.size.height/2)
        
        car1.size = CGSize (width: 100, height: 200)
        car1.zRotation = 3.14 * 90 / 90
        car1.zPosition = 10
        fgNode.addChild(car1)
        
        let actionMove =
            SKAction.moveTo(y: -car1.size.height, duration: 4.0)
        
        let actionRemove = SKAction.removeFromParent()
            car1.run(SKAction.sequence([actionMove, actionRemove]))
    
//        SKAction.move(
//            to: CGPoint(x: 0,
//                        y: 0),
//            duration: 3.0)
//        let actionRemove = SKAction.removeFromParent()
//        car1.run(SKAction.sequence([actionMove, actionRemove]))
        //car1.run(actionMove)
    }

    override func update(_ currentTime: TimeInterval){
        updateCamera()
    }
}


