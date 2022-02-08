//
//  ViewController.swift
//  orb_on_ios
//
//  Created by Donghan Kim on 2022/01/31.
//

import UIKit
import ARKit
import AVFoundation
import CoreMotion


class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var rgbImageView: UIImageView!
    @IBOutlet weak var depthImageView: UIImageView!
    private var ar_session = ARSession()
    var motion = CMMotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ar_session.delegate = self
        initARSession()
        initMotionCapture()
    }
    
    func initARSession(){
        let ARConfig = ARWorldTrackingConfiguration()
        ARConfig.frameSemantics = .sceneDepth
        ARConfig.worldAlignment = .gravity
        ARConfig.isAutoFocusEnabled = false
        ar_session.run(ARConfig)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func initMotionCapture(){
        motion.startAccelerometerUpdates()
        motion.startGyroUpdates()
        motion.startMagnetometerUpdates()
        
        motion.accelerometerUpdateInterval = 0.01
        motion.gyroUpdateInterval = 0.01
        motion.magnetometerUpdateInterval = 0.01
        
        motion.startDeviceMotionUpdates(to: .main) { (data, error) in
            guard let imu_raw = data else {
                return
            }
            /*
            self.accelx_label.text = String(format: "%.3f", imu_raw.userAcceleration.x)
            self.accely_label.text = String(format: "%.3f", imu_raw.userAcceleration.y)
            self.accelz_label.text = String(format: "%.3f", imu_raw.userAcceleration.z)
            
            self.gyrox_label.text = String(format: "%.3f", imu_raw.rotationRate.x)
            self.gyroy_label.text = String(format: "%.3f", imu_raw.rotationRate.y)
            self.gyroz_label.text = String(format: "%.3f", imu_raw.rotationRate.z)
            
            self.pitch.text = String(format: "%.3f", imu_raw.attitude.pitch)
            self.roll.text = String(format: "%.3f", imu_raw.attitude.roll)
            self.yaw.text = String(format: "%.3f", imu_raw.attitude.yaw)
            
            self.gravity_x.text = String(format: "%.3f", imu_raw.gravity.x)
            self.gravity_y.text = String(format: "%.3f", imu_raw.gravity.y)
            self.gravity_z.text = String(format: "%.3f", imu_raw.gravity.z)\
             */
        }
        
        motion.startMagnetometerUpdates(to: .main){ (data, error) in
            guard let mag_data = data else {
                return
            }
            /*
            self.magx_label.text = String(format: "%.3f", mag_data.magneticField.x)
            self.magy_label.text = String(format: "%.3f", mag_data.magneticField.y)
            self.magz_label.text = String(format: "%.3f", mag_data.magneticField.z)
             */
        }
        
        
    }
    
    // render frames to UI
    func renderFrames(frame: ARFrame){
        guard let orient = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation else { return }
        let rgb_viewportSize = rgbImageView.bounds.size
        let depth_viewportSize = depthImageView.bounds.size
        let rgb_tranform = frame.displayTransform(for: orient, viewportSize: rgb_viewportSize).inverted()
        let depth_transform = frame.displayTransform(for: orient, viewportSize: depth_viewportSize).inverted()
        var rgbImage: CIImage!
        var depthImage: CIImage!
        
        let rgbBuffer = frame.capturedImage
        rgbImage = CIImage(cvPixelBuffer: rgbBuffer).transformed(by: rgb_tranform)
        
        if let depthBuffer = frame.sceneDepth?.depthMap {
            depthImage = CIImage(cvPixelBuffer: depthBuffer).transformed(by: depth_transform)
        } else {
            print("could not obtain depth map from ARKit")
        }
        
        // for displaying results
        DispatchQueue.main.async {
            self.rgbImageView.image = UIImage(ciImage: rgbImage)
            if let depth = depthImage {
                self.depthImageView.image = UIImage(ciImage: depth)
            }
        }
    }
    
    // extract frames for network pass
    func extractFrames(frame: ARFrame) -> ([(UInt8, UInt8, UInt8)], [(UInt8, UInt8, UInt8)]){
        var rgb_frame = [(UInt8, UInt8, UInt8)](); var depth_frame = [(UInt8, UInt8, UInt8)]()
        
        // for rgb (1920x1440)
        let rgbBufferData = frame.capturedImage
        CVPixelBufferLockBaseAddress(rgbBufferData, CVPixelBufferLockFlags.readOnly)
        let rgb_base = CVPixelBufferGetBaseAddress(rgbBufferData)
        let rgb_bytes_per_row = CVPixelBufferGetBytesPerRow(rgbBufferData)
        let rgbBuffer = rgb_base!.assumingMemoryBound(to: UInt8.self)
        
        rgb_frame = create1DArray(buffer: rgbBuffer, width: CVPixelBufferGetWidth(rgbBufferData), height: CVPixelBufferGetHeight(rgbBufferData), bytes: rgb_bytes_per_row, rgb_flag: true)
                
        // for depth (256x192)
        if let depthBufferData = frame.sceneDepth?.depthMap {
            CVPixelBufferLockBaseAddress(depthBufferData, CVPixelBufferLockFlags.readOnly)
            let depth_base = CVPixelBufferGetBaseAddress(depthBufferData)
            let depth_bytes_per_row = CVPixelBufferGetBytesPerRow(depthBufferData)
            let depthBuffer = depth_base!.assumingMemoryBound(to: UInt8.self)
            
            depth_frame = create1DArray(buffer: depthBuffer, width: CVPixelBufferGetWidth(depthBufferData), height: CVPixelBufferGetHeight(depthBufferData), bytes: depth_bytes_per_row, rgb_flag: false)

        }
        return (rgb_frame, depth_frame)
    }
    
    func create1DArray(buffer: UnsafeMutablePointer<UInt8>, width: Int, height: Int, bytes: Int, rgb_flag:Bool) -> [(UInt8, UInt8, UInt8)] {
        var temp = [(UInt8, UInt8, UInt8)]()
        
        if rgb_flag {
            for i in 0..<width {
                for j in 0..<height {
                    if rgb_flag {
                        let idx = i*4 + j*bytes
                        let b = buffer[idx]; let g = buffer[idx+1]; let r = buffer[idx+2]
                        let new_pixel = (r,g,b)
                        temp.append(new_pixel)
                    }
                }
            }
        } else {
            let N = width*height
            for i in 0..<N {
                let new_pixel = (buffer[i], UInt8(0), UInt8(0))
                temp.append(new_pixel)
            }
        }
        return temp
    }
    
    // delegate functions
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        renderFrames(frame: frame)
        // let frame_data = extractFrames(frame: frame)
        
        
    }
}

