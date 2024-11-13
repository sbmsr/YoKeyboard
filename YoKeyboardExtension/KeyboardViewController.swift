import UIKit

private var keyRegions: [CAShapeLayer] = []

class KeyboardViewController: UIInputViewController {
    // MARK: - Properties
    private struct KeyboardMetrics {
        static let minKeyWidth: CGFloat = 24.0
        static let minKeyHeight: CGFloat = 36.0
        static let keySpacing: CGFloat = 4.0
        static let keyCornerRadius: CGFloat = 5.0
        static let rowSpacing: CGFloat = 8.0
        static let horizontalMargin: CGFloat = 4.0
    }
    
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
    
    private var touchAreas: [String: UIButton] = [:]
    
    private let trainingPhrase = "the quick brown fox jumped over the lazy dog"
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
    
    private var isTransitioning = false
    private var transitionLabel: UILabel!
    private var continueButton: UIButton!
    
    private var learnViewHeight: CGFloat = 180
    
    private let PIXEL_BOUNDARY: CGFloat = 8.0
    private let MIN_WIDTH: CGFloat = 20.0
    
    private var layoutData: [String: [String: Any]] = [:]
    
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
    
    
    
    private func setupKeyboard() {
        let keyboardStackView = UIStackView()
        keyboardStackView.axis = .vertical
        keyboardStackView.alignment = .fill
        keyboardStackView.distribution = .fillEqually
        keyboardStackView.spacing = 4
        keyboardStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // ... rest of keyboard setup remains the same ...
        
        view.addSubview(keyboardStackView)
        
        // Update keyboard constraints to position it below the labels
        NSLayoutConstraint.activate([
            keyboardStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            keyboardStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            keyboardStackView.topAnchor.constraint(equalTo: targetLetterLabel.bottomAnchor, constant: 20), // Position relative to label
            keyboardStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10) // Add bottom constraint
        ])
        
        keyboard = keyboardStackView
    }
    
    private func setupTargetLetterLabel() {
        targetLetterLabel = UILabel()
        targetLetterLabel.font = .systemFont(ofSize: 36, weight: .bold)
        targetLetterLabel.textAlignment = .center
        targetLetterLabel.isHidden = true
        targetLetterLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(targetLetterLabel)
        
        NSLayoutConstraint.activate([
            targetLetterLabel.topAnchor.constraint(equalTo: learnButton.bottomAnchor, constant: 10),
            targetLetterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            targetLetterLabel.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupMorphButton() {
        morphButton = UIButton(type: .system)
        morphButton.setTitle("Morph", for: .normal)  // Shortened text
        morphButton.addTarget(self, action: #selector(toggleMorphMode), for: .touchUpInside)
        morphButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(morphButton)
        
        NSLayoutConstraint.activate([
            morphButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            morphButton.bottomAnchor.constraint(equalTo: keyboard.topAnchor, constant: -5),
            morphButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupLearnButton() {
        learnButton = UIButton(type: .system)
        learnButton.setTitle("Learn", for: .normal)  // Shortened text
        learnButton.addTarget(self, action: #selector(toggleLearnMode), for: .touchUpInside)
        learnButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(learnButton)
        
        NSLayoutConstraint.activate([
            learnButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            learnButton.bottomAnchor.constraint(equalTo: keyboard.topAnchor, constant: -5),
            learnButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    // MARK: - Layout Building Methods
    private func buildOptimizedKeyboard(from layoutData: [String: [String: Any]]) {
        // Remove existing keyboard layout
        keyboard.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Group keys by rows based on Y positions
        let keysByRow = groupKeysIntoRows(layoutData)
        
        // Create keyboard rows
        for rowKeys in keysByRow {
            let rowStack = createKeyboardRow(keys: rowKeys, layoutData: layoutData)
            keyboard.addArrangedSubview(rowStack)
        }
        
        // Add spacebar row
        let spacebarRow = createSpacebarRow()
        keyboard.addArrangedSubview(spacebarRow)
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
    
    private func createKeyboardRow(keys: [String], layoutData: [String: [String: Any]]) -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = KeyboardMetrics.keySpacing
        rowStack.distribution = .fill
        rowStack.alignment = .center
        
        for key in keys {
            guard let keyData = layoutData[key] else { continue }
            let keyButton = createKeyButton(
                letter: key,
                metrics: keyData,
                totalRowWidth: view.bounds.width - (2 * KeyboardMetrics.horizontalMargin)
            )
            rowStack.addArrangedSubview(keyButton)
        }
        
        return rowStack
    }
    
    private func createKeyButton(letter: String, metrics: [String: Any], totalRowWidth: CGFloat) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(letter, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24)
        button.backgroundColor = .white
        button.layer.cornerRadius = KeyboardMetrics.keyCornerRadius
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        
        // Calculate optimal width based on statistics
        if let suggestedSize = metrics["suggestedSize"] as? [String: CGFloat],
           let width = suggestedSize["width"] {
            // Scale the width relative to the total row width
            let scaledWidth = max(
                KeyboardMetrics.minKeyWidth,
                min(width, totalRowWidth / 3) // Limit to 1/3 of row width
            )
            
            button.widthAnchor.constraint(equalToConstant: scaledWidth).isActive = true
        }
        
        // Calculate optimal height
        if let suggestedSize = metrics["suggestedSize"] as? [String: CGFloat],
           let height = suggestedSize["height"] {
            let scaledHeight = max(KeyboardMetrics.minKeyHeight, height)
            button.heightAnchor.constraint(equalToConstant: scaledHeight).isActive = true
        }
        
        button.addTarget(self, action: #selector(keyTapped(_:event:)), for: .touchUpInside)
        return button
    }
    
    private func createSpacebarRow() -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = KeyboardMetrics.keySpacing
        rowStack.distribution = .fill
        rowStack.alignment = .center
        
        let spacebar = UIButton(type: .system)
        spacebar.setTitle("space", for: .normal)
        spacebar.titleLabel?.font = .systemFont(ofSize: 16)
        spacebar.backgroundColor = .white
        spacebar.layer.cornerRadius = KeyboardMetrics.keyCornerRadius
        spacebar.layer.borderWidth = 1
        spacebar.layer.borderColor = UIColor.lightGray.cgColor
        spacebar.addTarget(self, action: #selector(keyTapped(_:event:)), for: .touchUpInside)
        
        rowStack.addArrangedSubview(spacebar)
        
        // Make spacebar fill the row
        spacebar.widthAnchor.constraint(equalToConstant: view.bounds.width - (2 * KeyboardMetrics.horizontalMargin)).isActive = true
        spacebar.heightAnchor.constraint(equalToConstant: KeyboardMetrics.minKeyHeight).isActive = true
        
        return rowStack
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
            isTransitioning = false
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
        isTransitioning = false  // Add this line
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
        guard state == .learn, !isTransitioning else { return }
        
        let location = gesture.location(in: keyboard)
        print("Learn mode tap received at: \(location)") // Debug log
        recordTapAndAdvance(at: location)
    }
    
    
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: keyboard)
        recordTapAndAdvance(at: location)
    }
    
    private func updateTargetLetter() {
        if currentPhraseIndex < trainingPhrase.count {
            let index = trainingPhrase.index(trainingPhrase.startIndex, offsetBy: currentPhraseIndex)
            targetLetterLabel.text = String(trainingPhrase[index])
        }
    }
    
    private func recordTapAndAdvance(at position: CGPoint) {
        guard currentPhraseIndex < trainingPhrase.count, !isTransitioning else { return }
        
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
        isTransitioning = true
        
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
                self.isTransitioning = false
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
            let suggestedWidth = max(MIN_WIDTH, confidenceBoundX * 2)  // 2x to cover both sides
            let suggestedHeight = max(MIN_WIDTH, confidenceBoundY * 2)
            
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
                    if abs(distanceFromCenter) > (sender.bounds.width/2 - PIXEL_BOUNDARY) {
                        let direction: CGFloat = distanceFromCenter > 0 ? 1 : -1
                        let changeAmount: CGFloat = PIXEL_BOUNDARY * direction
                        
                        var morphedNeighbor = false
                        
                        if direction > 0, index + 1 < stackView.arrangedSubviews.count {
                            let nextButton = stackView.arrangedSubviews[index + 1]
                            let newWidth = nextButton.frame.width - abs(changeAmount)
                            
                            if newWidth >= MIN_WIDTH {
                                if let nextWidthConstraint = nextButton.constraints.first(where: { $0.firstAttribute == .width }) {
                                    nextButton.removeConstraint(nextWidthConstraint)
                                }
                                nextButton.widthAnchor.constraint(equalToConstant: newWidth).isActive = true
                                morphedNeighbor = true
                            }
                            
                        } else if direction < 0, index - 1 >= 0 {
                            let previousButton = stackView.arrangedSubviews[index - 1]
                            let newWidth = previousButton.frame.width - abs(changeAmount)
                            
                            if newWidth >= MIN_WIDTH {
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
    
    private func buildOrganicKeyboard(from layoutData: [String: [String: Any]]) {
        // Remove existing keyboard content
        keyboard.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keyRegions.forEach { $0.removeFromSuperlayer() }
        keyRegions.removeAll()
        
        // Create container view for our organic keyboard
        let organicKeyboard = UIView()
        organicKeyboard.translatesAutoresizingMaskIntoConstraints = false
        keyboard.addArrangedSubview(organicKeyboard)
        
        NSLayoutConstraint.activate([
            organicKeyboard.heightAnchor.constraint(equalToConstant: learnViewHeight),
            organicKeyboard.widthAnchor.constraint(equalTo: keyboard.widthAnchor)
        ])
        
        // Extract key centers from layout data
        var keyCenters: [(key: String, point: CGPoint)] = []
        for (key, data) in layoutData {
            if let meanData = data["mean"] as? [String: CGFloat],
               let x = meanData["x"],
               let y = meanData["y"] {
                keyCenters.append((key: key, point: CGPoint(x: x, y: y)))
            }
        }
        
        // Add boundary points to ensure the Voronoi diagram fills the keyboard
        let bounds = keyboard.bounds
        let padding: CGFloat = 20
        let boundaryPoints = [
            ("bound1", CGPoint(x: -padding, y: -padding)),
            ("bound2", CGPoint(x: bounds.width + padding, y: -padding)),
            ("bound3", CGPoint(x: bounds.width + padding, y: bounds.height + padding)),
            ("bound4", CGPoint(x: -padding, y: bounds.height + padding)),
            ("bound5", CGPoint(x: bounds.width/2, y: -padding)),
            ("bound6", CGPoint(x: bounds.width/2, y: bounds.height + padding)),
            ("bound7", CGPoint(x: -padding, y: bounds.height/2)),
            ("bound8", CGPoint(x: bounds.width + padding, y: bounds.height/2))
        ]
        
        let allPoints = keyCenters + boundaryPoints
        
        // Create Voronoi regions for each key
        for (idx, centerPoint) in keyCenters.enumerated() {
            let region = createVoronoiRegion(
                for: centerPoint.point,
                key: centerPoint.key,
                allPoints: allPoints.map { $0.point },
                bounds: bounds
            )
            
            // Create and style the key region
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = region.cgPath
            shapeLayer.fillColor = UIColor.white.cgColor
            shapeLayer.strokeColor = UIColor.lightGray.cgColor
            shapeLayer.lineWidth = 1.0
            
            // Add key label
            let label = UILabel()
            label.text = centerPoint.key
            label.font = .systemFont(ofSize: 24)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            
            // Create touch area
            let touchArea = UIButton()
            touchArea.backgroundColor = .clear
            touchArea.tag = idx
            touchArea.addTarget(self, action: #selector(organicKeyTapped(_:)), for: .touchUpInside)
            touchArea.translatesAutoresizingMaskIntoConstraints = false
            
            organicKeyboard.layer.addSublayer(shapeLayer)
            organicKeyboard.addSubview(touchArea)
            organicKeyboard.addSubview(label)
            
            // Position label at key center
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: organicKeyboard.leadingAnchor, constant: centerPoint.point.x),
                label.centerYAnchor.constraint(equalTo: organicKeyboard.topAnchor, constant: centerPoint.point.y),
                
                touchArea.leadingAnchor.constraint(equalTo: organicKeyboard.leadingAnchor),
                touchArea.trailingAnchor.constraint(equalTo: organicKeyboard.trailingAnchor),
                touchArea.topAnchor.constraint(equalTo: organicKeyboard.topAnchor),
                touchArea.bottomAnchor.constraint(equalTo: organicKeyboard.bottomAnchor)
            ])
            
            keyRegions.append(shapeLayer)
        }
        
        // Add spacebar at the bottom
        addOrganicSpacebar(to: organicKeyboard)
    }
    
    private func createVoronoiRegion(for center: CGPoint, key: String, allPoints: [CGPoint], bounds: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        
        // For each other point, create a line that's equidistant between our center and that point
        for otherPoint in allPoints where otherPoint != center {
            // Find midpoint between centers
            let midX = (center.x + otherPoint.x) / 2
            let midY = (center.y + otherPoint.y) / 2
            
            // Calculate perpendicular vector
            let dx = otherPoint.x - center.x
            let dy = otherPoint.y - center.y
            let perpX = -dy
            let perpY = dx
            
            // Normalize and extend perpendicular vector
            let length = sqrt(perpX * perpX + perpY * perpY)
            let normalizedPerpX = perpX / length * bounds.width * 2
            let normalizedPerpY = perpY / length * bounds.height * 2
            
            // Create line segment perpendicular to center-other line
            let lineStart = CGPoint(x: midX + normalizedPerpX, y: midY + normalizedPerpY)
            let lineEnd = CGPoint(x: midX - normalizedPerpX, y: midY - normalizedPerpY)
            
            // Add to path
            if path.isEmpty {
                path.move(to: lineStart)
                path.addLine(to: lineEnd)
            } else {
                let currentPath = path.copy() as! UIBezierPath
                path.removeAllPoints()
                
                // Clip current path with new line
                let clipPath = UIBezierPath()
                clipPath.move(to: lineStart)
                clipPath.addLine(to: lineEnd)
                
                // Create rectangle to close the path
                clipPath.addLine(to: CGPoint(x: lineEnd.x + normalizedPerpX, y: lineEnd.y + normalizedPerpY))
                clipPath.addLine(to: CGPoint(x: lineStart.x + normalizedPerpX, y: lineStart.y + normalizedPerpY))
                clipPath.close()
                
                // Add the intersected region
                path.append(currentPath)
                path.append(clipPath)
            }
        }
        
        // Clip to keyboard bounds
        let boundingBox = UIBezierPath(rect: bounds)
        path.append(boundingBox)
        
        return path
    }
    
    
    
    private func addOrganicSpacebar(to keyboardView: UIView) {
        let spacebarHeight: CGFloat = 40
        let spacebarMargin: CGFloat = 8
        
        let spacebarLayer = CAShapeLayer()
        let spacebarPath = UIBezierPath(
            roundedRect: CGRect(
                x: spacebarMargin,
                y: keyboardView.bounds.height - spacebarHeight - spacebarMargin,
                width: keyboardView.bounds.width - (spacebarMargin * 2),
                height: spacebarHeight
            ),
            cornerRadius: 8
        )
        
        spacebarLayer.path = spacebarPath.cgPath
        spacebarLayer.fillColor = UIColor.white.cgColor
        spacebarLayer.strokeColor = UIColor.lightGray.cgColor
        spacebarLayer.lineWidth = 1.0
        
        keyboardView.layer.addSublayer(spacebarLayer)
        
        let spacebarButton = UIButton()
        spacebarButton.setTitle("space", for: .normal)
        spacebarButton.setTitleColor(.black, for: .normal)
        spacebarButton.titleLabel?.font = .systemFont(ofSize: 16)
        spacebarButton.addTarget(self, action: #selector(spacebarTapped), for: .touchUpInside)
        spacebarButton.translatesAutoresizingMaskIntoConstraints = false
        
        keyboardView.addSubview(spacebarButton)
        
        NSLayoutConstraint.activate([
            spacebarButton.leadingAnchor.constraint(equalTo: keyboardView.leadingAnchor, constant: spacebarMargin),
            spacebarButton.trailingAnchor.constraint(equalTo: keyboardView.trailingAnchor, constant: -spacebarMargin),
            spacebarButton.bottomAnchor.constraint(equalTo: keyboardView.bottomAnchor, constant: -spacebarMargin),
            spacebarButton.heightAnchor.constraint(equalToConstant: spacebarHeight)
        ])
    }
    
    @objc private func organicKeyTapped(_ sender: UIButton) {
        guard let keyRegion = keyRegions[safe: sender.tag],
              let character = keyRegion.value(forKey: "character") as? String else {
            return
        }
        
        switch state {
        case .default:
            textDocumentProxy.insertText(character)
        case .learn:
            let location = sender.center
            recordTapAndAdvance(at: location)
        case .morph:
            // Handle morph mode if needed
            break
        }
    }
    
    @objc private func spacebarTapped(_ sender: UIButton) {
        textDocumentProxy.insertText(" ")
    }
    
    
    deinit {
        cleanupLearnMode()
    }
    
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension KeyboardViewController {
    private func buildVoronoiKeyboard(from layoutData: [String: [String: Any]]) {
        self.layoutData = layoutData
        // Clear existing keyboard
        keyboard.arrangedSubviews.forEach { $0.removeFromSuperview() }
        touchAreas.removeAll()
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
                    // Create a unique color for each key
                    let hue = CGFloat(key.unicodeScalars.first?.value ?? 0) / 255.0
                    let color = UIColor(hue: hue, saturation: 0.7, brightness: 0.9, alpha: 0.3)
                    context.setFillColor(color.cgColor)
                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        
        // Create image from context
        guard let voronoiImage = UIGraphicsGetImageFromCurrentImageContext() else { return }
        UIGraphicsEndImageContext()
        
        // Create image view to display the Voronoi diagram
        let imageView = UIImageView(image: voronoiImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        
        // Add key labels and touch areas
        for (key, data) in layoutData {
            if let meanData = data["mean"] as? [String: CGFloat],
               let x = meanData["x"],
               let y = meanData["y"] {
                // Add label
                let label = UILabel()
                label.text = key
                label.font = .systemFont(ofSize: 24)
                label.textAlignment = .center
                label.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(label)
                
                // Add touch area
                let button = UIButton()
                button.backgroundColor = .clear
                button.setTitle(key, for: .normal)
                button.accessibilityIdentifier = key
                // In buildVoronoiKeyboard, update the button target:
                button.addTarget(self, action: #selector(voronoiKeyTapped(_:event:)), for: .touchUpInside)
                button.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(button)
                
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: containerView.leadingAnchor, constant: x),
                    label.centerYAnchor.constraint(equalTo: containerView.topAnchor, constant: y),
                    
                    // Create a fixed-size touch area around the key center
                    button.widthAnchor.constraint(equalToConstant: 44),  // Reasonable touch target size
                    button.heightAnchor.constraint(equalToConstant: 44),
                    button.centerXAnchor.constraint(equalTo: containerView.leadingAnchor, constant: x),
                    button.centerYAnchor.constraint(equalTo: containerView.topAnchor, constant: y)
                ])
                
                
                touchAreas[key] = button
            }
        }
        
        // Add spacebar
        //        addVoronoiSpacebar(to: containerView)
    }
    
    @objc private func voronoiKeyTapped(_ sender: UIButton, event: UIEvent? = nil) {
        guard let touch = event?.allTouches?.first else { return }
        let location = touch.location(in: keyboard)
        
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
    private func addVoronoiSpacebar(to containerView: UIView) {
        // Similar to previous spacebar implementation
        let spacebarHeight: CGFloat = 40
        let spacebarMargin: CGFloat = 8
        
        let spacebarLayer = CAShapeLayer()
        let spacebarPath = UIBezierPath(
            roundedRect: CGRect(
                x: spacebarMargin,
                y: containerView.bounds.height - spacebarHeight - spacebarMargin,
                width: containerView.bounds.width - (spacebarMargin * 2),
                height: spacebarHeight
            ),
            cornerRadius: 8
        )
        
        spacebarLayer.path = spacebarPath.cgPath
        spacebarLayer.fillColor = UIColor.white.cgColor
        spacebarLayer.strokeColor = UIColor.lightGray.cgColor
        spacebarLayer.lineWidth = 1.0
        
        containerView.layer.addSublayer(spacebarLayer)
    }
}

// Core data structures for Fortune's algorithm
struct VEdge: Equatable {
    var start: CGPoint
    var end: CGPoint?
    let left: VPoint
    let right: VPoint
    
    // Direction vector of the edge
    var direction: CGPoint {
        let dx = right.y - left.y
        let dy = -(right.x - left.x)
        let len = sqrt(dx * dx + dy * dy)
        return CGPoint(x: dx/len, y: dy/len)
    }
    
    static func == (lhs: VEdge, rhs: VEdge) -> Bool {
        return lhs.start == rhs.start &&
        lhs.end == rhs.end &&
        lhs.left == rhs.left &&
        lhs.right == rhs.right
    }
}

// Also need to make VPoint Equatable
struct VPoint: Hashable, Equatable {
    let x: CGFloat
    let y: CGFloat
    let key: String
    
    func distance(to other: VPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
    //
    //    static func == (lhs: VPoint, rhs: VPoint) -> Bool {
    //        return lhs.key == rhs.key
    //    }
    //
    static func == (lhs: VPoint, rhs: VPoint) -> Bool {
        return lhs.x == rhs.x &&
        lhs.y == rhs.y &&
        lhs.key == rhs.key
    }
}
enum VEvent {
    case site(point: VPoint)
    case circle(center: CGPoint, point: VPoint, radius: CGFloat)
    
    var y: CGFloat {
        switch self {
        case .site(let point): return point.y
        case .circle(let center, _, let radius): return center.y - radius
        }
    }
}

class BeachLine {
    class Arc {
        var point: VPoint
        var prev: Arc?
        var next: Arc?
        var event: VEvent?
        var leftEdge: VEdge?
        var rightEdge: VEdge?
        
        init(point: VPoint) {
            self.point = point
        }
    }
    
    private var root: Arc?
    
    func insert(point: VPoint, at x: CGFloat) -> [Arc] {
        if root == nil {
            root = Arc(point: point)
            return [root!]
        }
        
        // Find the arc above this point
        var arc = root
        while arc != nil {
            // Calculate break points
            if isPointBelow(point: point, arc: arc!, sweepline: x) {
                if arc?.next == nil {
                    // Add new arc at the end
                    let newArc = Arc(point: point)
                    arc?.next = newArc
                    newArc.prev = arc
                    return [newArc]
                }
                arc = arc?.next
            } else {
                break
            }
        }
        
        // Split the arc
        let newArc = Arc(point: point)
        let oldArc = Arc(point: arc!.point)
        
        newArc.prev = arc?.prev
        newArc.next = oldArc
        oldArc.prev = newArc
        oldArc.next = arc?.next
        arc?.next = newArc
        
        return [newArc, oldArc]
    }
    
    private func isPointBelow(point: VPoint, arc: Arc, sweepline: CGFloat) -> Bool {
        // Calculate parabola intersection
        let p = arc.point
        if p.y == point.y { return point.x > p.x }
        
        let dp = 2.0 * (p.y - sweepline)
        if dp == 0 { return point.x > p.x }
        
        let a1 = 1.0 / dp
        let b1 = -2.0 * p.x / dp
        let c1 = sweepline + dp / 4.0 + p.x * p.x / dp
        
        let y = a1 * point.x * point.x + b1 * point.x + c1
        return point.y > y
    }
}

class FortuneVoronoi {
    private var events: [VEvent] = []
    private let beachLine = BeachLine()
    private var edges: [VEdge] = []
    private var vertices: [CGPoint] = []
    
    func generate(from points: [VPoint], bounds: CGRect) -> [VEdge] {
        events = points.map { VEvent.site(point: $0) }
        events.sort { $0.y > $1.y }
        
        print("Starting Fortune's algorithm with \(points.count) points")
        
        while !events.isEmpty {
            let event = events.removeLast()
            
            switch event {
            case .site(let point):
                print("Processing site event for point \(point.key)")
                handleSiteEvent(point)
            case .circle(let center, let point, _):
                print("Processing circle event at \(center) for point \(point.key)")
                handleCircleEvent(center, point)
            }
        }
        
        finishEdges(bounds: bounds)
        print("Generated \(edges.count) edges")
        edges.forEach { edge in
            print("Edge: \(edge.left.key) -> \(edge.right.key)")
        }
        
        return edges
    }
    
    private func handleSiteEvent(_ point: VPoint) {
        let newArcs = beachLine.insert(point: point, at: point.y)
        
        // Create edges between this point and its neighbors
        if let arc = newArcs.first {
            if let prev = arc.prev {
                // Add edge between current point and previous point
                let edge = VEdge(
                    start: CGPoint(
                        x: (point.x + prev.point.x) / 2,
                        y: (point.y + prev.point.y) / 2
                    ),
                    end: nil,
                    left: prev.point,
                    right: point
                )
                edges.append(edge)
            }
            
            if let next = arc.next {
                // Add edge between current point and next point
                let edge = VEdge(
                    start: CGPoint(
                        x: (point.x + next.point.x) / 2,
                        y: (point.y + next.point.y) / 2
                    ),
                    end: nil,
                    left: point,
                    right: next.point
                )
                edges.append(edge)
            }
        }
        
        checkCircleEvent(arcs: newArcs)
    }
    
    private func handleCircleEvent(_ center: CGPoint, _ point: VPoint) {
        // Add vertex
        vertices.append(center)
        
        // Create new edge
        let edge = VEdge(start: center, end: nil, left: point, right: point)
        edges.append(edge)
    }
    
    private func checkCircleEvent(arcs: [BeachLine.Arc]) {
        for arc in arcs {
            if let prev = arc.prev, let next = arc.next {
                let circle = computeCircle(p1: prev.point, p2: arc.point, p3: next.point)
                if let (center, radius) = circle {
                    events.append(.circle(center: center, point: arc.point, radius: radius))
                    events.sort { $0.y > $1.y }
                }
            }
        }
    }
    
    private func computeCircle(p1: VPoint, p2: VPoint, p3: VPoint) -> (center: CGPoint, radius: CGFloat)? {
        // Circle computation using circumcenter of three points
        let d = 2 * (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y))
        if abs(d) < CGFloat.ulpOfOne { return nil }
        
        let ux = ((p1.x * p1.x + p1.y * p1.y) * (p2.y - p3.y) +
                  (p2.x * p2.x + p2.y * p2.y) * (p3.y - p1.y) +
                  (p3.x * p3.x + p3.y * p3.y) * (p1.y - p2.y)) / d
        
        let uy = ((p1.x * p1.x + p1.y * p1.y) * (p3.x - p2.x) +
                  (p2.x * p2.x + p2.y * p2.y) * (p1.x - p3.x) +
                  (p3.x * p3.x + p3.y * p3.y) * (p2.x - p1.x)) / d
        
        let center = CGPoint(x: ux, y: uy)
        let radius = p1.distance(to: VPoint(x: center.x, y: center.y, key: ""))
        
        return (center, radius)
    }
    
    private func finishEdges(bounds: CGRect) {
        // Add boundary intersections
        let boundaryEdges = edges
        edges.removeAll()
        
        for edge in boundaryEdges {
            if edge.end == nil {
                let direction = edge.direction
                let end = findIntersection(start: edge.start,
                                           direction: direction,
                                           bounds: bounds)
                edges.append(VEdge(start: edge.start,
                                   end: end,
                                   left: edge.left,
                                   right: edge.right))
            } else {
                edges.append(edge)
            }
        }
        
        // Add bounding box edges if needed
        let boundingBox = [
            CGPoint(x: bounds.minX, y: bounds.minY),
            CGPoint(x: bounds.maxX, y: bounds.minY),
            CGPoint(x: bounds.maxX, y: bounds.maxY),
            CGPoint(x: bounds.minX, y: bounds.maxY)
        ]
        
        for i in 0..<boundingBox.count {
            let start = boundingBox[i]
            let end = boundingBox[(i + 1) % boundingBox.count]
            let edge = VEdge(start: start,
                             end: end,
                             left: VPoint(x: start.x, y: start.y, key: "boundary"),
                             right: VPoint(x: end.x, y: end.y, key: "boundary"))
            edges.append(edge)
        }
    }
    
    private func findIntersection(start: CGPoint, direction: CGPoint, bounds: CGRect) -> CGPoint {
        // Find intersection with bounding box
        var tMin = CGFloat.infinity
        var intersection = start
        
        // Check each boundary
        let boundaries = [
            (p1: CGPoint(x: bounds.minX, y: bounds.minY),
             p2: CGPoint(x: bounds.maxX, y: bounds.minY)),
            (p1: CGPoint(x: bounds.maxX, y: bounds.minY),
             p2: CGPoint(x: bounds.maxX, y: bounds.maxY)),
            (p1: CGPoint(x: bounds.maxX, y: bounds.maxY),
             p2: CGPoint(x: bounds.minX, y: bounds.maxY)),
            (p1: CGPoint(x: bounds.minX, y: bounds.maxY),
             p2: CGPoint(x: bounds.minX, y: bounds.minY))
        ]
        
        for (p1, p2) in boundaries {
            if let t = lineIntersection(start: start, direction: direction,
                                        p1: p1, p2: p2) {
                if t > 0 && t < tMin {
                    tMin = t
                    intersection = CGPoint(x: start.x + direction.x * t,
                                           y: start.y + direction.y * t)
                }
            }
        }
        
        return intersection
    }
    
    private func lineIntersection(start: CGPoint, direction: CGPoint,
                                  p1: CGPoint, p2: CGPoint) -> CGFloat? {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let det = dx * direction.y - dy * direction.x
        
        if abs(det) < CGFloat.ulpOfOne { return nil }
        
        let t = ((p1.x - start.x) * direction.y - (p1.y - start.y) * direction.x) / det
        if t < 0 || t > 1 { return nil }
        
        let s = ((p1.x - start.x) * dy - (p1.y - start.y) * dx) / det
        if s < 0 { return nil }
        
        return s
    }
}
