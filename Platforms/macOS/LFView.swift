import Foundation
import AVFoundation

open class LFView: NSView {
    public static var defaultBackgroundColor:NSColor = NSColor.black
    fileprivate var snapshotCallback: ((CIImage?) -> ())?

    public func snapshot(callback aCallback: @escaping (CIImage?) -> ()) {
       guard nil != self.currentStream else {
         aCallback(nil)
         return
       }
       self.snapshotCallback = aCallback
    }

    public var videoGravity:String = AVLayerVideoGravityResizeAspect {
        didSet {
            layer?.setValue(videoGravity, forKey: "videoGravity")
        }
    }

    var position:AVCaptureDevicePosition = .front {
        didSet {
            DispatchQueue.main.async {
                self.layer?.setNeedsLayout()
            }
        }
    }
    var orientation:AVCaptureVideoOrientation = .portrait

    private weak var currentStream:NetStream? {
        didSet {
            self.snapshotCallback?(nil)
            self.snapshotCallback = nil

            guard let oldValue:NetStream = oldValue else {
                return
            }
            oldValue.mixer.videoIO.drawable = nil
        }
    }

    override public init(frame: NSRect) {
        super.init(frame: frame)
        awakeFromNib()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open override func awakeFromNib() {
        wantsLayer = true
        layer = AVCaptureVideoPreviewLayer()
        layer?.backgroundColor = LFView.defaultBackgroundColor.cgColor
        layer?.setValue(videoGravity, forKey: "videoGravity")
    }

    open func attachStream(_ stream:NetStream?) {
        currentStream = stream
        guard let stream:NetStream = stream else {
            layer?.setValue(nil, forKey: "session")
            return
        }
        stream.lockQueue.async {
            self.layer?.setValue(stream.mixer.session, forKey: "session")
            stream.mixer.videoIO.drawable = self
            stream.mixer.startRunning()
        }
    }
}

extension LFView: NetStreamDrawable {
    // MARK: NetStreamDrawable
    func draw(image:CIImage) {
      self.snapshotCallback?(image)
      self.snapshotCallback = nil
    }
}
