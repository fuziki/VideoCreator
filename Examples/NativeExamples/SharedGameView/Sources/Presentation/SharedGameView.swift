//
//  SharedGameView.swift
//  SharedGameView
//
//  Created by fuziki on 2021/08/15.
//

import Combine
import Foundation
import SceneKit
import UIKit

public class SharedGameView: UIView {

    private let lastNextDrawableTextureSubject = PassthroughSubject<MTLTexture, Never>()
    public let lastNextDrawableTexturePublisher: AnyPublisher<MTLTexture, Never>
    public var lastNextDrawableTexture: MTLTexture? {
        return (scnView.layer as! CAMetalLayer).lastNextDrawableTexture
    }

    public var drawableSize: CGSize {
        return (scnView.layer as! CAMetalLayer).drawableSize
    }

    private let scnView: SCNView

    override init(frame: CGRect) {
        scnView = SCNView(frame: .zero)
        lastNextDrawableTexturePublisher = lastNextDrawableTextureSubject.eraseToAnyPublisher()
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        scnView = SCNView(frame: .zero)
        lastNextDrawableTexturePublisher = lastNextDrawableTextureSubject.eraseToAnyPublisher()
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        CAMetalLayer.setupLastNextDrawableTexture()

        // retrieve the SCNView
        self.addSubview(scnView)

        let scene = makeScene()
        setupScnView(scene: scene)

        scnView.delegate = self

        let layer = scnView.layer as! CAMetalLayer
        layer.framebufferOnly = false
    }

    private func makeScene() -> SCNScene {
        // create a new scene
        let url = Bundle(for: SharedGameView.self).resourceURL!.appendingPathComponent("art.scnassets/ship.scn")
        let scene = try! SCNScene(url: url, options: nil)

        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)

        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)

        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)

        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)

        // retrieve the ship node
        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!

        // animate the 3d object
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))

        return scene
    }

    private func setupScnView(scene: SCNScene) {
        scnView.translatesAutoresizingMaskIntoConstraints = false
        scnView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        scnView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        scnView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        scnView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true

        // set the scene to the view
        scnView.scene = scene

        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true

        // show statistics such as fps and timing information
        scnView.showsStatistics = true

        // configure the view
        scnView.backgroundColor = UIColor.black

        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.subviews.first! as! SCNView

        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]

            // get its material
            let material = result.node.geometry!.firstMaterial!

            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5

            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5

                material.emission.contents = UIColor.black

                SCNTransaction.commit()
            }

            material.emission.contents = UIColor.red

            SCNTransaction.commit()
        }
    }
}

extension SharedGameView: SCNSceneRendererDelegate {
    public func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            guard let layer = self?.scnView.layer as? CAMetalLayer,
                  let texture = layer.lastNextDrawableTexture else {
                return
            }
            self?.lastNextDrawableTextureSubject.send(texture)
        }
    }
}
