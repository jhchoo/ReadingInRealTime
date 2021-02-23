//
//  AudioPowerVisualizerView.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/23.
//

import UIKit
import AVFoundation

class AudioPowerVisualizerView: UIView {
    
    // Configuration Settings
    private let animatioтDuration = 0.1
    private let maxPowerDelta: CGFloat = 30
    private let minScale: CGFloat = 0.9

    open var isPlaying: Bool = false {
        didSet {
            if isPlaying == false {
                transform = .identity
            }
        }
    }

    // Animate self transform depends on player meters
    func updateMeters(power: CGFloat) {
        UIView.animate(withDuration: animatioтDuration, animations: {
            self.animate(to: power)
        }) { [weak self] (_) in
            guard let self = self else { return }
            
            if !self.isPlaying {
                self.transform = .identity
            }
        }
    }

    // Apply scale transform depends on power
    private func animate(to power: CGFloat) {
        let powerDelta = (maxPowerDelta + power) * 2 / 1000
        let compute: CGFloat = minScale + powerDelta
        let scale: CGFloat = CGFloat.maximum(compute, minScale)
        self.transform = CGAffineTransform(scaleX: scale, y: scale)
    }

}
