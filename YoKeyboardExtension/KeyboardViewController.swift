import UIKit


class KeyboardViewController: UIInputViewController {
    private var keys = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
        ["spacebar"]
    ]
    
    enum State {
        case `default`
        case morph
        case learn
    }
    
    struct TapRecord {
        let letter: String
        let position: CGPoint
        let iteration: Int
    }
    
    private struct KeyboardMetrics {
        static let minKeyWidth: CGFloat = 20.0
        static let minKeyHeight: CGFloat = 36.0
        static let keySpacing: CGFloat = 4.0
        static let keyCornerRadius: CGFloat = 5.0
        static let rowSpacing: CGFloat = 8.0
        static let horizontalMargin: CGFloat = 4.0
    }
    
    private var keyRegions: [CAShapeLayer] = []
    private var layoutData: [String: [String: Any]] = [:]
    
    private let trainingPhrase = "the quick brown fox jumps over the lazy dog"
    private var currentPhraseIndex = 0
    private var currentIteration = 1
    private let totalIterations = 3
    private var tapRecords: [Character: [TapRecord]] = [:]
    private var tapGesture: UITapGestureRecognizer?
    private var learnModeView: UIView?
    
    private var keyboard: UIStackView!
    private var morphButton: UIButton!
    private var learnButton: UIButton!
    private var targetLetterLabel: UILabel!
    
    private var state: State = .default
    private var isMorphModeEnabled = false
    
    private var transitionLabel: UILabel!
    private var continueButton: UIButton!
    
    private var learnViewHeight: CGFloat = 180
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupTransitionViews()
    }
    
    private func setupViews() {
        // Create all UI elements first
        morphButton = UIButton(type: .system)
        morphButton.setTitle("Morph", for: .normal)
        morphButton.addTarget(self, action: #selector(toggleMorphMode), for: .touchUpInside)
        morphButton.translatesAutoresizingMaskIntoConstraints = false
        
        learnButton = UIButton(type: .system)
        learnButton.setTitle("Learn", for: .normal)
        learnButton.addTarget(self, action: #selector(toggleLearnMode), for: .touchUpInside)
        learnButton.translatesAutoresizingMaskIntoConstraints = false
        
        targetLetterLabel = UILabel()
        targetLetterLabel.font = .systemFont(ofSize: 36, weight: .bold)
        targetLetterLabel.textAlignment = .center
        targetLetterLabel.isHidden = true
        targetLetterLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let keyboardStackView = UIStackView()
        keyboardStackView.axis = .vertical
        keyboardStackView.alignment = .fill
        keyboardStackView.distribution = .fillEqually
        keyboardStackView.spacing = 4
        keyboardStackView.translatesAutoresizingMaskIntoConstraints = false
        keyboard = keyboardStackView
        
        // Add all views to hierarchy
        view.addSubview(keyboard)
        view.addSubview(morphButton)
        view.addSubview(learnButton)
        view.addSubview(targetLetterLabel)
        
        // Setup keyboard rows and keys
        for row in keys {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.alignment = .fill
            rowStackView.distribution = .fillEqually // or .fillProportionally depending on your needs
            rowStackView.spacing = 4
            
            for k in row {
                let key = UIButton(type: .system)
                key.setTitle(k, for: .normal)
                key.titleLabel?.font = UIFont.systemFont(ofSize: 24)
                key.layer.borderWidth = 2
                key.layer.borderColor = UIColor.white.cgColor
                key.layer.cornerRadius = 5
                key.setTitleColor(UIColor.black, for: .normal)
                key.backgroundColor = UIColor.white
                key.addTarget(self, action: #selector(keyTapped(_:event:)), for: .touchUpInside)
                key.setContentHuggingPriority(.defaultLow, for: .vertical) // Add this
                key.setContentCompressionResistancePriority(.defaultLow, for: .vertical) // Add this
                rowStackView.addArrangedSubview(key)
            }
            keyboard.addArrangedSubview(rowStackView)
        }
        
        // Setup all constraints together
        NSLayoutConstraint.activate([
            // Keyboard constraints
            keyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            keyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            keyboard.topAnchor.constraint(equalTo: targetLetterLabel.bottomAnchor, constant: 8),
            keyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            keyboard.heightAnchor.constraint(equalToConstant: learnViewHeight),  // Add fixed height constraint
            
            // Button and label constraints
            morphButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            morphButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),  // Anchor to top
            morphButton.heightAnchor.constraint(equalToConstant: 30),
            
            learnButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            learnButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),  // Anchor to top
            learnButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Target letter label constraints
            targetLetterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            targetLetterLabel.centerYAnchor.constraint(equalTo: morphButton.centerYAnchor),
            targetLetterLabel.heightAnchor.constraint(equalToConstant: 44)
        ])
        
    }
    
    private func setupTransitionViews() {
        transitionLabel = UILabel()
        transitionLabel.font = .systemFont(ofSize: 24, weight: .medium)
        transitionLabel.textAlignment = .center
        transitionLabel.textColor = .systemBlue
        transitionLabel.isHidden = true
        transitionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        continueButton = UIButton(type: .system)
        continueButton.setTitle("Tap to continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 20)
        continueButton.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
        continueButton.isHidden = true
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(transitionLabel)
        view.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            transitionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            transitionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.topAnchor.constraint(equalTo: transitionLabel.bottomAnchor, constant: 20)
        ])
    }
    
    private func groupKeysIntoRows(_ layoutData: [String: [String: Any]]) -> [[String]] {
        // Extract Y positions for each key
        var keyPositions: [(key: String, y: CGFloat)] = []
        
        for (key, data) in layoutData {
            if let meanData = data["mean"] as? [String: CGFloat],
               let yPos = meanData["y"] {
                keyPositions.append((key: key, y: yPos))
            }
        }
        
        // Sort by Y position
        let sortedKeys = keyPositions.sorted { $0.y < $1.y }
        
        // Group into rows (using clustering based on Y positions)
        var rows: [[String]] = []
        var currentRow: [String] = []
        var lastY: CGFloat = -1
        
        for keyPosition in sortedKeys {
            if lastY == -1 {
                currentRow.append(keyPosition.key)
            } else if abs(keyPosition.y - lastY) < KeyboardMetrics.minKeyHeight {
                currentRow.append(keyPosition.key)
            } else {
                rows.append(currentRow)
                currentRow = [keyPosition.key]
            }
            lastY = keyPosition.y
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    @objc private func toggleMorphMode() {
        isMorphModeEnabled.toggle()
        state = isMorphModeEnabled ? .morph : .default
        
        let title = isMorphModeEnabled ? "Stop" : "Morph"  // Shortened toggle text
        morphButton.setTitle(title, for: .normal)
    }
    
    // Update toggleLearnMode to handle phrase progression
    @objc private func toggleLearnMode() {
        switch state {
        case .default:
            state = .learn
            isMorphModeEnabled = false
            morphButton.isEnabled = false
            learnButton.setTitle("Stop", for: .normal)
            targetLetterLabel.isHidden = false
            currentPhraseIndex = 0
            currentIteration = 1
            tapRecords.removeAll()
            updateTargetLetter()
            
            // Remove existing learn mode view if it exists
            learnModeView?.removeFromSuperview()
            learnModeView = nil
            
            // Create and add a new blank view over the keyboard
            learnModeView = UIView()
            learnModeView?.backgroundColor = .darkGray
            if let learnView = learnModeView {
                keyboard.addSubview(learnView)
                learnView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    learnView.topAnchor.constraint(equalTo: keyboard.topAnchor),
                    learnView.bottomAnchor.constraint(equalTo: keyboard.bottomAnchor),
                    learnView.leadingAnchor.constraint(equalTo: keyboard.leadingAnchor),
                    learnView.trailingAnchor.constraint(equalTo: keyboard.trailingAnchor)
                ])
                
                // Remove any existing gesture recognizer
                if let existingGesture = tapGesture {
                    learnView.removeGestureRecognizer(existingGesture)
                }
                
                // Add new tap gesture to the blank view
                tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLearnModeTap(_:)))
                if let gesture = tapGesture {
                    learnView.addGestureRecognizer(gesture)
                    learnView.isUserInteractionEnabled = true
                }
                
                // Ensure the learn view is on top
                keyboard.bringSubviewToFront(learnView)
            }
            
            // Hide the keyboard buttons
            keyboard.arrangedSubviews.forEach { rowView in
                guard let row = rowView as? UIStackView else { return }
                row.arrangedSubviews.forEach { button in
                    button.isHidden = true
                }
            }
            
        case .learn:
            cleanupLearnMode()
            
        case .morph:
            return
        }
        
    }
    
    private func cleanupLearnMode() {
        state = .default
        morphButton.isEnabled = true
        learnButton.setTitle("Learn", for: .normal)
        targetLetterLabel.isHidden = true
        
        // Clean up learn mode view and gesture recognizer
        if let learnView = learnModeView {
            if let gesture = tapGesture {
                learnView.removeGestureRecognizer(gesture)
            }
            learnView.removeFromSuperview()
        }
        learnModeView = nil
        tapGesture = nil
        
        // If we completed all iterations, generate the layout
        if currentIteration > totalIterations {
            generateKeyboardLayout()
        }
    }
    
    @objc private func handleLearnModeTap(_ gesture: UITapGestureRecognizer) {
        guard state == .learn else { return }
        
        let location = gesture.location(in: keyboard)
        print("Learn mode tap received at: \(location)") // Debug log
        recordTapAndAdvance(at: location)
    }
    
    private func updateTargetLetter() {
        if currentPhraseIndex < trainingPhrase.count {
            let index = trainingPhrase.index(trainingPhrase.startIndex, offsetBy: currentPhraseIndex)
            targetLetterLabel.text = String(trainingPhrase[index])
        }
    }
    
    private func recordTapAndAdvance(at position: CGPoint) {
        guard currentPhraseIndex < trainingPhrase.count else { return }
        
        let index = trainingPhrase.index(trainingPhrase.startIndex, offsetBy: currentPhraseIndex)
        let letter = trainingPhrase[index]
        
        // Record the tap
        let record = TapRecord(letter: String(letter), position: position, iteration: currentIteration)
        if tapRecords[letter] == nil {
            tapRecords[letter] = []
        }
        tapRecords[letter]?.append(record)
        
        // Advance to next letter
        currentPhraseIndex += 1
        
        // Check if we completed the phrase
        if currentPhraseIndex >= trainingPhrase.count {
            showTransition()
        } else {
            updateTargetLetter()
        }
    }
    
    private func showTransition() {
        // Hide keyboard interaction view and target letter
        learnModeView?.isHidden = true
        targetLetterLabel.isHidden = true
        
        // Show transition UI
        transitionLabel.text = "Iteration \(currentIteration) complete!\nStarting iteration \(currentIteration + 1) of \(totalIterations)"
        transitionLabel.isHidden = false
        continueButton.isHidden = false
        
        // Animate the transition UI
        transitionLabel.alpha = 0
        continueButton.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.transitionLabel.alpha = 1
            self.continueButton.alpha = 1
        }
    }
    
    @objc private func handleContinue() {
        // Hide transition UI
        UIView.animate(withDuration: 0.3, animations: {
            self.transitionLabel.alpha = 0
            self.continueButton.alpha = 0
        }) { _ in
            self.transitionLabel.isHidden = true
            self.continueButton.isHidden = true
            
            // Reset for next iteration
            self.currentPhraseIndex = 0
            self.currentIteration += 1
            
            // Check if we're done with all iterations
            if self.currentIteration > self.totalIterations {
                self.toggleLearnMode()
            } else {
                // Show keyboard interaction view and target letter
                self.learnModeView?.isHidden = false
                self.targetLetterLabel.isHidden = false
                self.updateTargetLetter()
            }
        }
    }
    
    
    private func generateKeyboardLayout() {
        var positionsDict: [String: [String: Any]] = [:]
        
        for (letter, records) in tapRecords {
            // Calculate means
            let count = CGFloat(records.count)
            let meanX = records.reduce(0) { $0 + $1.position.x } / count
            let meanY = records.reduce(0) { $0 + $1.position.y } / count
            
            // Calculate variances
            let varianceX = records.reduce(0) { $0 + pow($1.position.x - meanX, 2) } / count
            let varianceY = records.reduce(0) { $0 + pow($1.position.y - meanY, 2) } / count
            
            // Calculate standard deviations
            let stdDevX = sqrt(varianceX)
            let stdDevY = sqrt(varianceY)
            
            // Calculate extreme points
            let minX = records.map { $0.position.x }.min() ?? 0
            let maxX = records.map { $0.position.x }.max() ?? 0
            let minY = records.map { $0.position.y }.min() ?? 0
            let maxY = records.map { $0.position.y }.max() ?? 0
            
            // Calculate spread (range)
            let spreadX = maxX - minX
            let spreadY = maxY - minY
            
            // Calculate median positions
            let sortedX = records.map { $0.position.x }.sorted()
            let sortedY = records.map { $0.position.y }.sorted()
            
            let medianX = count.truncatingRemainder(dividingBy: 2) == 0
            ? (sortedX[Int(count/2) - 1] + sortedX[Int(count/2)]) / 2
            : sortedX[Int(count/2)]
            let medianY = count.truncatingRemainder(dividingBy: 2) == 0
            ? (sortedY[Int(count/2) - 1] + sortedY[Int(count/2)]) / 2
            : sortedY[Int(count/2)]
            
            
            // Calculate inter-quartile range (IQR)
            let q1X = sortedX[Int(count * 0.25)]
            let q3X = sortedX[Int(count * 0.75)]
            let q1Y = sortedY[Int(count * 0.25)]
            let q3Y = sortedY[Int(count * 0.75)]
            let iqrX = q3X - q1X
            let iqrY = q3Y - q1Y
            
            // Calculate confidence bounds (using 2 standard deviations = ~95% confidence)
            let confidenceBoundX = stdDevX * 2
            let confidenceBoundY = stdDevY * 2
            
            // Suggested key dimensions based on statistical measures
            let suggestedWidth = max(KeyboardMetrics.minKeyWidth, confidenceBoundX * 2)  // 2x to cover both sides
            let suggestedHeight = max(KeyboardMetrics.minKeyHeight, confidenceBoundY * 2)
            
            // Calculate hit accuracy (percentage of taps within 1 std dev of mean)
            let tapsWithinStdDev = records.filter { tap in
                let distanceX = abs(tap.position.x - meanX)
                let distanceY = abs(tap.position.y - meanY)
                return distanceX <= stdDevX && distanceY <= stdDevY
            }.count
            let accuracy = Double(tapsWithinStdDev) / Double(count) * 100
            
            positionsDict[String(letter)] = [
                // Position statistics
                "mean": ["x": meanX, "y": meanY],
                "median": ["x": medianX, "y": medianY],
                "variance": ["x": varianceX, "y": varianceY],
                "stdDev": ["x": stdDevX, "y": stdDevY],
                
                // Range statistics
                "min": ["x": minX, "y": minY],
                "max": ["x": maxX, "y": maxY],
                "spread": ["x": spreadX, "y": spreadY],
                "iqr": ["x": iqrX, "y": iqrY],
                
                // Key size suggestions
                "suggestedSize": [
                    "width": suggestedWidth,
                    "height": suggestedHeight
                ],
                
                // Additional metrics
                "sampleCount": count,
                "accuracy": accuracy,
                "confidenceBounds": [
                    "x": confidenceBoundX,
                    "y": confidenceBoundY
                ]
            ]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: positionsDict, options: [.prettyPrinted])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("KEYBOARD_LAYOUT:", jsonString)
                
                // Replace buildOptimizedKeyboard with buildVoronoiKeyboard
                buildVoronoiKeyboard(from: positionsDict)  // <-- This is the key change
                
                // Save layout data if needed
                if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let filePath = documentsPath.appendingPathComponent("keyboard_layout.json")
                    try jsonString.write(to: filePath, atomically: true, encoding: .utf8)
                    print("Saved to:", filePath.path)
                }
            }
        } catch {
            print("Error generating JSON:", error)
        }
    }
    
    @objc private func keyTapped(_ sender: UIButton, event: UIEvent) {
        if let touch = event.allTouches?.first {
            let tapLocation = touch.location(in: keyboard)
            
            switch state {
            case .learn:
                // In learn mode, we don't care about which button was tapped
                recordTapAndAdvance(at: tapLocation)
                
            case .morph:
                // For morph mode, we need the button title
                guard let keyTitle = sender.title(for: .normal) else { return }
                
                let tapLocationInButton = touch.location(in: sender)
                let buttonCenter = sender.bounds.midX
                
                let distanceFromCenter = tapLocationInButton.x - buttonCenter
                
                let rowStackView = keyboard.arrangedSubviews.first { row in
                    guard let rowStackView = row as? UIStackView else { return false }
                    return rowStackView.arrangedSubviews.contains { key in
                        guard let button = key as? UIButton else { return false }
                        return button.currentTitle == sender.currentTitle
                    }
                }
                
                if let stackView = rowStackView as? UIStackView, let index = stackView.arrangedSubviews.firstIndex(of: sender) {
                    if abs(distanceFromCenter) > (sender.bounds.width/2 - KeyboardMetrics.keySpacing) {
                        let direction: CGFloat = distanceFromCenter > 0 ? 1 : -1
                        let changeAmount: CGFloat = KeyboardMetrics.keySpacing * direction
                        
                        var morphedNeighbor = false
                        
                        if direction > 0, index + 1 < stackView.arrangedSubviews.count {
                            let nextButton = stackView.arrangedSubviews[index + 1]
                            let newWidth = nextButton.frame.width - abs(changeAmount)
                            
                            if newWidth >= KeyboardMetrics.minKeyWidth {
                                if let nextWidthConstraint = nextButton.constraints.first(where: { $0.firstAttribute == .width }) {
                                    nextButton.removeConstraint(nextWidthConstraint)
                                }
                                nextButton.widthAnchor.constraint(equalToConstant: newWidth).isActive = true
                                morphedNeighbor = true
                            }
                            
                        } else if direction < 0, index - 1 >= 0 {
                            let previousButton = stackView.arrangedSubviews[index - 1]
                            let newWidth = previousButton.frame.width - abs(changeAmount)
                            
                            if newWidth >= KeyboardMetrics.minKeyWidth {
                                if let prevWidthConstraint = previousButton.constraints.first(where: { $0.firstAttribute == .width }) {
                                    previousButton.removeConstraint(prevWidthConstraint)
                                }
                                previousButton.widthAnchor.constraint(equalToConstant: newWidth).isActive = true
                                morphedNeighbor = true
                            }
                        }
                        
                        if morphedNeighbor {
                            if let widthConstraint = sender.constraints.first(where: { $0.firstAttribute == .width }) {
                                sender.removeConstraint(widthConstraint)
                            }
                            
                            sender.widthAnchor.constraint(equalToConstant: sender.frame.width + abs(changeAmount)).isActive = true
                        }
                        
                        UIView.animate(withDuration: 0.1) {
                            self.view.layoutIfNeeded()
                        }
                    }
                }
                
            case .default:
                // For default mode, we need the button title
                guard let keyTitle = sender.title(for: .normal) else { return }
                textDocumentProxy.insertText(keyTitle)
            }
        }
    }
    
    @objc private func spacebarTapped(_ sender: UIButton) {
        textDocumentProxy.insertText(" ")
    }
    
    
    deinit {
        cleanupLearnMode()
    }
    
}

extension KeyboardViewController {
    private func buildVoronoiKeyboard(from layoutData: [String: [String: Any]]) {
        self.layoutData = layoutData
        // Clear existing keyboard
        keyboard.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keyRegions.removeAll()
        
        // Create container view
        let containerView = UIView(frame: keyboard.bounds)
        keyboard.addArrangedSubview(containerView)
        
        // Create image context with the same size as keyboard
        UIGraphicsBeginImageContext(containerView.bounds.size)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // For each pixel in the keyboard area
        let width = Int(containerView.bounds.width)
        let height = Int(containerView.bounds.height)
        
        for x in 0..<width {
            for y in 0..<height {
                var minDist = CGFloat.infinity
                var closestKey: String?
                
                // Find the closest key center
                for (key, data) in layoutData {
                    if let meanData = data["mean"] as? [String: CGFloat],
                       let centerX = meanData["x"],
                       let centerY = meanData["y"] {
                        let dist = sqrt(pow(CGFloat(x) - centerX, 2) + pow(CGFloat(y) - centerY, 2))
                        if dist < minDist {
                            minDist = dist
                            closestKey = key
                        }
                    }
                }
                
                // Color the pixel based on the closest key
                if let key = closestKey {
                    // Use predefined colors for each key
                    let keyColors: [String: UIColor] = [
                        "q": UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.3),      // Red
                        "w": UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.3),      // Green  
                        "e": UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.3),      // Blue
                        "r": UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.3),      // Yellow
                        "t": UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 0.3),      // Magenta
                        "y": UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 0.3),      // Cyan
                        "u": UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.3),      // Orange
                        "i": UIColor(red: 0.5, green: 0.0, blue: 1.0, alpha: 0.3),      // Purple
                        "o": UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 0.3),      // Dark Green
                        "p": UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.3),      // Light Blue
                        "a": UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 0.3),      // Pink
                        "s": UIColor(red: 0.5, green: 1.0, blue: 0.0, alpha: 0.3),      // Lime
                        "d": UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.3),      // Sky Blue
                        "f": UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.3),      // Light Red
                        "g": UIColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 0.3),      // Light Green
                        "h": UIColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 0.3),      // Olive
                        "j": UIColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 0.3),      // Teal
                        "k": UIColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 0.3),      // Dark Purple
                        "l": UIColor(red: 0.7, green: 0.4, blue: 0.0, alpha: 0.3),      // Brown
                        "z": UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.3),      // Light Gray
                        "x": UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.3),      // Gray
                        "c": UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.3),      // Dark Gray
                        "v": UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.3),      // Gold
                        "b": UIColor(red: 0.8, green: 0.2, blue: 1.0, alpha: 0.3),      // Violet
                        "n": UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.3),      // Azure
                        "m": UIColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 0.3),      // Peach
                    ]
                    
                    if let color = keyColors[key] {
                        context.setFillColor(color.cgColor)
                        context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                    }
                }
            }
        }
        
        // Create image from context
        guard let voronoiImage = UIGraphicsGetImageFromCurrentImageContext() else { return }
        UIGraphicsEndImageContext()
        
        // Create image view to display the Voronoi diagram
        let imageView = UIImageView(image: voronoiImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true  // Make it interactive
        containerView.addSubview(imageView)
        
        // Add tap gesture recognizer to the image view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleVoronoiTap(_:)))
        imageView.addGestureRecognizer(tapGesture)
        
        // Add constraints for the image view to fill the container
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        // Add key labels and touch areas
        for (key, data) in layoutData {
            if let meanData = data["mean"] as? [String: CGFloat],
               let x = meanData["x"],
               let y = meanData["y"] {
                // Add label for the key
                let label = UILabel()
                label.text = key
                label.textAlignment = .center
                label.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(label)
                
                NSLayoutConstraint.activate([
                    label.widthAnchor.constraint(equalToConstant: 44),
                    label.heightAnchor.constraint(equalToConstant: 44),
                    label.centerXAnchor.constraint(equalTo: containerView.leadingAnchor, constant: x),
                    label.centerYAnchor.constraint(equalTo: containerView.topAnchor, constant: y)
                ])
                
                
            }
        }
        
    }
    
    @objc private func handleVoronoiTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: gesture.view)
        
        // Find the closest key to the touch location
        var minDist = CGFloat.infinity
        var closestKey: String?
        
        for (key, data) in layoutData {
            if let meanData = data["mean"] as? [String: CGFloat],
               let centerX = meanData["x"],
               let centerY = meanData["y"] {
                let dist = sqrt(pow(location.x - centerX, 2) + pow(location.y - centerY, 2))
                if dist < minDist {
                    minDist = dist
                    closestKey = key
                }
            }
        }
        
        if let key = closestKey {
            switch state {
            case .default:
                textDocumentProxy.insertText(key)
            case .learn:
                recordTapAndAdvance(at: location)
            case .morph:
                break
            }
        }
    }
}
