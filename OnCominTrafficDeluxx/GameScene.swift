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
    var lastOverlayPos = CGPoint.zero
    var coin : SKSpriteNode!
    var lastOverlayHeight: CGFloat=0.0
    var levelPositionY: CGFloat=0.0
    let cameraNode = SKCameraNode()
    var cops : SKSpriteNode!
    var lastUpdateTimeInterval: TimeInterval = 0
    var deltaTime: TimeInterval = 0
    
    override func didMove(to view: SKView) {
        SetupNodes()
        SetupTransition()
        let scale = SKAction.scale(to:1.0, duration: 0.5)
        fgNode.childNode(withName: "Ready")!.run(scale)
        physicsWorld.contactDelegate = self
        SetUpCoreMotion()
    }
    
    func updatLevel() {
        let cameraPos = camera!.position
        if cameraPos.y > levelPositionY - size.height {
        createBackground()
            while lastOverlayPos.y < levelPositionY {
                addRandomBackground()
            }
        }
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
        cops = fgNode.childNode(withName: "Cops") as! SKSpriteNode
        coin = fgNode.childNode(withName: "Coin") as! SKSpriteNode
        levelPositionY = bgNode.childNode(withName: "Overlay")!.position.y + bgOverlayHeight
        while lastOverlayPos.y < levelPositionY{
            addRandomBackground()
        }
        
    }
    
    func updateCamera(){
        let cameraTarget = convert(player.position,from: fgNode)
        let targetPositionY = cameraTarget.y - (size.height * -0.15)
        let diff = targetPositionY - camera!.position.y
        let cameraLagFactor: CGFloat = 0.1
        let lagDiff = diff * cameraLagFactor
        let newCameraPositionY = camera!.position.y + lagDiff
        camera!.position.y = newCameraPositionY
    }
    
    func UpdateCopCollision(){
        if player.position.y < cops.position.y + 90 {
            playerState = .dead
            setPlayerSetVelocity(750)
        }
    }
    
    func updateCops(_ dt: TimeInterval){
        let bottomOfScreen = camera!.position.y - (size.height / 2)
        let bottomOfScreenFG = convert(CGPoint(x: 0, y: bottomOfScreen), to: fgNode).y
        let copsVel = CGFloat(750)
        let CopsStep = copsVel * CGFloat(dt)
        var newCopsPos = cops.position.y + CopsStep
        newCopsPos = max(newCopsPos, bottomOfScreen - 125.0)
        cops.position.y = newCopsPos
    }
    
    func StartGame(){
        gameState = .playing
        let scale = SKAction.scale(to: 0, duration:  0.4)
        fgNode.childNode(withName: "Title")!.run(scale)
        fgNode.childNode(withName: "Ready")!.run(
        SKAction.sequence(
            [SKAction.wait(forDuration: 0.2), scale]))
        player.physicsBody!.isDynamic = true
        setPlayerSetVelocity(750)
    
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
        lastOverlayPos.y = lastOverlayPos.y + (lastOverlayHeight + (foregroundOverlay.size.height / 1.5))
        lastOverlayHeight = foregroundOverlay.size.height / 2
        foregroundOverlay.position = lastOverlayPos
        if (flipX == true)
        {
            foregroundOverlay.xScale = -1.0
        }
        fgNode.addChild(foregroundOverlay)
    }
    
    func addRandomBackground(){
        let overlaySprite: SKSpriteNode
        let platformPercentage = 60
        if Int.random(min: 1, max: 100) <= platformPercentage {
            overlaySprite = coin
        } else {
            overlaySprite = coin
        }
        createForeground(overlaySprite, flipX: false)
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

    override func update(_ currentTime: TimeInterval){
        
        if lastUpdateTimeInterval > 0 {
            deltaTime = currentTime  - lastUpdateTimeInterval
        }else{
            deltaTime = 0
        }
        lastUpdateTimeInterval = currentTime
        if isPaused {
            return
        }
        if gameState == .playing {
            updateCamera()
            updatLevel()
            updateCops(deltaTime)
            UpdateCopCollision()
        }
    }
}


