//
//  ARViewController.swift
//  SamMiti-Example
//
//  Created by Nattawut Singhchai on 30/1/18.
//  Copyright © 2018 Prolific Interactive. All rights reserved.
//

import UIKit
import ARKit
import SamMitiAR
import GLTFSceneKit

class ARViewController: UIViewController {
    
    let virtualObjectLoader = SamMitiVitualObjectLoader()

    @IBOutlet weak var optionView: UIView!
    
    @IBOutlet weak var closeOptionButton: UIButton!
    @IBOutlet weak var resetOptionButton: UIButton!
    
    @IBOutlet weak var optionLightInsentityValueLabel: UILabel!
    @IBOutlet weak var optionHitTestPointXLabel: UILabel!
    @IBOutlet weak var optionHitTestPointYLabel: UILabel!
    
    @IBOutlet weak var samMitiARView: SamMitiARView!
    
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var optionButton: UIButton!
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var messageLabel: UILabel!
    
    var previousIsIdleTimerDisabled: Bool!
    
    var debugOptions: SamMitiDebugOptions = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // User Interface Setup
        addButton.layer.cornerRadius = 32
        optionButton.layer.cornerRadius = 16
        resetButton.layer.cornerRadius = 16
        optionView.layer.cornerRadius = 40
        closeOptionButton.layer.cornerRadius = 16
        resetOptionButton.layer.cornerRadius = 16
        
        messageLabel.text = ""
        
        optionView.transform.ty = UIScreen.main.bounds.height
        optionView.isHidden = true
        
        // SamMiti View mandatory delegate
        samMitiARView.samMitiARDelegate = self
        
        // SamMiti View Configuration
        samMitiARView.isAutoFocusEnabled = false
        samMitiARView.hitTestPlacingPoint = CGPoint(x: 0.5, y: 0.5)
        samMitiARView.isLightingIntensityAutomaticallyUpdated = true
        samMitiARView.baseLightingEnvironmentIntensity = 6
        samMitiARView.scene.lightingEnvironment.contents = #imageLiteral(resourceName: "environment.jpg")
        
        samMitiARView.focusNode = SamMitiFocusNode(withNotFoundNamed: "art.scnassets/focus-node/defaultFocusNotFound.scn",
                                                   estimatedNamed: "art.scnassets/focus-node/defaultFocusEstimated.scn",
                                                   existingNamed: "art.scnassets/focus-node/defaultFocusExisting.scn")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Store isIdleTimerDisabled Value
        previousIsIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
        
        // Keep screen on all the time
        UIApplication.shared.isIdleTimerDisabled = true
        samMitiARView.startAR(withDebugOptions: debugOptions)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Reset Stored isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = previousIsIdleTimerDisabled
        
        // Pause the view's AR session.
        samMitiARView.session.pause()
    }

    // Prevent implicit transition animation of SamMitiView.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.samMitiARView.performTransitionWithOutAnimation(to: size, parentViewCenterPoint: view.center)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func resetButtonDidTouch(_ sender: UIButton) {
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        let alert = UIAlertController(title: "Reset AR", message: "Do you want to reset this AR scene?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { _ in
            self.virtualObjectLoader.removeAllVirtualObjects()
            self.samMitiARView.resetAR(withDebugOptions: self.debugOptions)
            self.handleLoad(virtualNode: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        
        
    }
    
    @IBAction func optionButtonDidTouch(_ sender: UIButton) {
        isDebugOptionShown = true
    }
    
    var isDebugOptionShown: Bool = false {
        didSet {
            let offsetValue: CGFloat = 360
            if isDebugOptionShown {
                self.optionView.isHidden = false
                self.optionView.transform.ty = UIScreen.main.bounds.height
                
                UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                    
                    self.optionView.alpha = 1
                    
                    self.addButton.alpha = 0
                    self.optionButton.alpha = 0
                    self.resetButton.alpha = 0
                    
                    self.optionView.transform = CGAffineTransform.identity
                    
                    self.addButton.transform.ty = -offsetValue
                    self.optionButton.transform.ty = -offsetValue
                    self.resetButton.transform.ty = -offsetValue
                }, completion: nil)
            } else {
                
                UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                    
                    self.optionView.alpha = 0
                    
                    self.addButton.alpha = 1
                    self.optionButton.alpha = 1
                    self.resetButton.alpha = 1
                    
                    self.optionView.transform.ty = offsetValue
                    
                    self.addButton.transform = CGAffineTransform.identity
                    self.optionButton.transform = CGAffineTransform.identity
                    self.resetButton.transform = CGAffineTransform.identity
                }, completion: { _ in
                    self.optionView.isHidden = true
                })
            }
        }
    }
    
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                loadingIndicator.isHidden = false
                addButton.isHidden = true
            }else{
                loadingIndicator.isHidden = true
                addButton.isHidden = false
            }
        }
    }
    
    func handleLoad(virtualNode: SamMitiVirtualObject?) {
        guard let virtualNode = virtualNode else {
            return
        }
        isLoading = false
        samMitiARView.currentVirtualObject = virtualNode
        
        // Print Virtual Node Name
        print(virtualNode.name ?? "Undefined Virtual Object Name")
        
        // Example shows how to access to the content of the Virtual Node
        guard let virtualContainNode = virtualNode.contentNode else {
            return
        }
        print(virtualContainNode)
    }
    
    func remove(virtualNode: SamMitiVirtualObject?) {
        guard let virtualNode = virtualNode else {
            return
        }
        isLoading = false
        samMitiARView.currentVirtualObject = virtualNode
        
        if samMitiARView.placedVirtualObjects.contains(virtualNode) {
            let alert = UIAlertController(title: "Delete", message: "Do you want to delete \(virtualNode.name ?? "this object")?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.virtualObjectLoader.remove(virtualNode)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    var clearMessageTimer: Timer?
    
    func messageLabelDisplay(_ messageText: String) {
        clearMessageTimer = nil
        messageLabel.text = messageText
        
        clearMessageTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (timer) in
            self.messageLabel.text = ""
        }
    }
    
    @IBAction func addButtonDidTouch(_ sender: UIButton) {
        guard !isLoading else { return }
        
        let sheetController = UIAlertController(title: "Create", message: nil, preferredStyle: .actionSheet)
        
        sheetController.addAction(UIAlertAction(title: "Profile Pic", style: .default, handler: { (action) in
            self.virtualObjectLoader.loadVirtualObject(.plane, loadedHandler: self.handleLoad)
        }))
        
        sheetController.addAction(UIAlertAction(title: "Helmet — GLTF Model", style: .default, handler: { (action) in
            self.isLoading = true
            self.virtualObjectLoader.loadVirtualObject(.helmet, loadedHandler: { virtualObjectNode in
                let scaleTransfrom = SCNMatrix4MakeScale(0.2, 0.2, 0.2)
                virtualObjectNode.contentNode?.transform = scaleTransfrom
                virtualObjectNode.contentNode?.pivot = SCNMatrix4MakeTranslation(0, virtualObjectNode.contentNode?.boundingBox.min.y ?? 0, 0)
                self.handleLoad(virtualNode: virtualObjectNode)
            })
        }))
        
        sheetController.addAction(UIAlertAction(title: "York St. Station", style: .default, handler: { (action) in
            self.isLoading = true
            self.virtualObjectLoader.loadVirtualObject(.yorkStreetStation, loadedHandler: { virtualObjectNode in
                self.handleLoad(virtualNode: virtualObjectNode)
            })
        }))
        
        sheetController.addAction(UIAlertAction(title: "Hamburger — Eat It!", style: .default, handler: { (action) in
            self.isLoading = true
            self.virtualObjectLoader.loadVirtualObject(.hamburger, loadedHandler: { virtualObjectNode in
                self.handleLoad(virtualNode: virtualObjectNode)
            })
        }))
        
        sheetController.addAction(UIAlertAction(title: "Duck", style: .default, handler: { (action) in
            self.isLoading = true
            self.virtualObjectLoader.loadVirtualObject(.duck, loadedHandler: { virtualObjectNode in
                virtualObjectNode.contentNode?.transform = SCNMatrix4MakeScale(0.06, 0.06, 0.06)
                self.handleLoad(virtualNode: virtualObjectNode)
            })
        }))
        
        sheetController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        sheetController.popoverPresentationController?.sourceView = sender
        present(sheetController, animated: true, completion: nil)
    }
    
    @IBAction func optionShowDebugStatusButtonDidTouch(_ sender: UISwitch) {
        if sender.isOn {
            debugOptions.insert(.showStateStatus)
        } else {
            if debugOptions.contains(.showStateStatus) {
                debugOptions.remove(.showStateStatus)
            }
        }
    }
    
    @IBAction func optionShowAnchorPlanesButtonDidTouch(_ sender: UISwitch) {
        if sender.isOn {
            debugOptions.insert(.showAnchorPlane)
        } else {
            if debugOptions.contains(.showAnchorPlane) {
                debugOptions.remove(.showAnchorPlane)
            }
        }
    }
    
    @IBAction func optionLightingAutomaticallyButtonDidTouch(_ sender: UISwitch) {
        samMitiARView.isLightingIntensityAutomaticallyUpdated = sender.isOn
    }
    
    @IBAction func optionLightIntensityMultiplierSliderValueDidChange(_ sender: UISlider) {
        let textValue = String(round(sender.value * 10) / 10)
        optionLightInsentityValueLabel.text = textValue
        samMitiARView.baseLightingEnvironmentIntensity = CGFloat(sender.value)
    }
    
    @IBAction func optionHitTestPointXSliderValueDidChange(_ sender: UISlider) {
        let textValue = String(round(sender.value * 100) / 100)
        optionHitTestPointXLabel.text = textValue
        samMitiARView.hitTestPlacingPoint.x = CGFloat(sender.value)
    }
    
    @IBAction func optionHitTestPointYSliderValueDidChange(_ sender: UISlider) {
        let textValue = String(round(sender.value * 100) / 100)
        optionHitTestPointYLabel.text = textValue
        samMitiARView.hitTestPlacingPoint.y = CGFloat(sender.value)
    }
    
    @IBAction func optionCloseButtonDidTouch(_ sender: UIButton) {
        isDebugOptionShown = false
    }
}

extension ARViewController: SamMitiARDelegate {
    
    // MARK: SamMiti Status Delegate
    
    func trackingStateChanged(to trackingState: SamMitiTrackingState) {
        switch trackingState {
        case .normal:
            messageLabelDisplay("Tracking: Normal")
        case .notAvailable:
            messageLabelDisplay("Tracking: Not Available")
        case .limited:
            break
        }
    }
    
    func trackingStateReasonChanged(to trackingStateReason: ARCamera.TrackingState.Reason?) {
        guard let trackingStateReason = trackingStateReason else { return }
        switch trackingStateReason {
        case ARCamera.TrackingState.Reason.excessiveMotion:
            messageLabelDisplay("Tracking: Limited - Excessive Motion")
        case ARCamera.TrackingState.Reason.initializing:
            messageLabelDisplay("Tracking: Limited - Initializing")
        case ARCamera.TrackingState.Reason.insufficientFeatures:
            messageLabelDisplay("Tracking: Limited - Insufficient Features")
        case ARCamera.TrackingState.Reason.relocalizing:
            messageLabelDisplay("Tracking: Limited - Relocalizing")
        }
    }
    
    func interactionStatusChanged(to interactionStatus: SamMitiInteractionStatus) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    func hitTestDistanceChanged(to distance: CGFloat?) {
        
    }
    
    func alignmentChanged(to alignment: ARPlaneAnchor.Alignment?) {
        
    }
    
    func planeDetectingConfidentLevelChanged(to confidentLevel: PlaneDetectingConfidentLevel?) {
        
        
    }
    
    // MARK: SamMiti Virtual Object Hit Test Gesture Delegate
    
    func samMitiViewWillPlace(_ virtualObject: SamMitiVirtualObject, at transform: SCNMatrix4) {
        guard let virtualObjectName = virtualObject.name else { return }
        messageLabelDisplay("SamMiti will place \(virtualObjectName)")
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    func samMitiViewDidPlace(_ virtualObject: SamMitiVirtualObject) {
        guard let virtualObjectName = virtualObject.name else { return }
        messageLabelDisplay("SamMiti placed \(virtualObjectName)")
    }
    
    func samMitiViewDidTap(on virtualObject: SamMitiVirtualObject?) {
        handleLoad(virtualNode: virtualObject)
        
        guard let virtualObjectName = virtualObject?.name else { return }
        messageLabelDisplay("SamMiti tapped on Virtual Object Name: \(virtualObjectName)")
    }
    
    func samMitiViewDidDoubleTap(on virtualObject: SamMitiVirtualObject?) {
        guard let virtualObject = virtualObject else { return }
        if let virtualObjectName = virtualObject.name {
            messageLabelDisplay("SamMiti double tapped on Virtual Object Name: \(virtualObjectName)")
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        remove(virtualNode: virtualObject)
    }
    
    func samMitiViewDidLongPress(on virtualObject: SamMitiVirtualObject?) {
        
        
        guard let virtualObjectName = virtualObject?.name else { return }
        messageLabelDisplay("SamMiti Long Pressed on Virtual Object Name: \(virtualObjectName)")
    }
    
    // MARK: SamMiti Virtual Object Manipulating Gesture Delegate
    /*
    func samMitiViewWillBeginTranslating(virtualObject: SamMitiVirtualObject?) {
        guard let virtualObjectName = virtualObject?.name else { return }
        messageLabelDisplay("SamMiti will begin translating \(virtualObjectName)")
    }
    
    func samMitiViewIsTranslating(virtualObject: SamMitiVirtualObject) {
        guard let virtualObjectName = virtualObject.name else {
            messageLabelDisplay("SamMiti is translating to (x: \(virtualObject.position.x), y: \(virtualObject.position.y), z: \(virtualObject.position.z))")
            return }
        messageLabelDisplay("SamMiti is translating \(virtualObjectName) to (x: \(virtualObject.position.x), y: \(virtualObject.position.y), z: \(virtualObject.position.z))")
    }
    
    func samMitiViewDidTranslate(virtualObject: SamMitiVirtualObject?) {
        guard let virtualObject = virtualObject else { return }
        guard let virtualObjectName = virtualObject.name else {
            messageLabelDisplay("SamMiti translated to (x: \(virtualObject.position.x), y: \(virtualObject.position.y), z: \(virtualObject.position.z))")
            return }
        messageLabelDisplay("SamMiti translated \(virtualObjectName) to (x: \(virtualObject.position.x), y: \(virtualObject.position.y), z: \(virtualObject.position.z))")
    }
    
    func samMitiViewWillBeginRotating(virtualObject: SamMitiVirtualObject?) {
        guard let virtualObjectName = virtualObject?.name else { return }
        messageLabelDisplay("SamMiti will begin rotating \(virtualObjectName)")
    }
    
    func samMitiViewIsRotating(virtualObject: SamMitiVirtualObject) {
        guard let virtualObjectName = virtualObject.name else {
            messageLabelDisplay("SamMiti is rotating to \(virtualObject.virtualRotation)")
            return }
        messageLabelDisplay("SamMiti is rotating \(virtualObjectName) to \(virtualObject.virtualRotation)")
    }
    
    func samMitiViewDidRotate(virtualObject: SamMitiVirtualObject?) {
        guard let virtualObjectName = virtualObject?.name else {
            messageLabelDisplay("SamMiti rotated")
            return }
        messageLabelDisplay("SamMiti rotated \(virtualObjectName)")
    }
    
    func samMitiViewWillBeginPinching(virtualObject: SamMitiVirtualObject?) {
        guard let virtualObjectName = virtualObject?.name else { return }
        messageLabelDisplay("SamMiti will begin pinching \(virtualObjectName)")
    }
    
    func samMitiViewIsPinching(virtualObject: SamMitiVirtualObject) {
        guard let virtualObjectName = virtualObject.name else {
            messageLabelDisplay("SamMiti is pinching to \(virtualObject.virtualScale)")
            return }
        messageLabelDisplay("SamMiti is pinching \(virtualObjectName) to \(virtualObject.virtualScale)")
    }
    
    func samMitiViewDidPinch(virtualObject: SamMitiVirtualObject?) {
        guard let virtualObject = virtualObject else { return }
        guard let virtualObjectName = virtualObject.name else {
            messageLabelDisplay("SamMiti is pinching to \(virtualObject.virtualScale)")
            return }
        messageLabelDisplay("SamMiti is pinching \(virtualObjectName) to \(virtualObject.virtualScale)")
    }
 */
}
