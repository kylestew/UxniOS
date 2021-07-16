import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var bgRenderView: UIView!
    @IBOutlet weak var fgRenderView: UIView!

    var uxn: UxnBridge = UxnBridge()

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tapGesture.minimumPressDuration = 0
        fgRenderView.addGestureRecognizer(tapGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // wait to load app UI before executing ROM
        let rom = Bundle.main.path(forResource: "bifurcan", ofType: "rom")!

        uxn.load(rom)

        startRenderLoop()

        // currently the screen size is hardwired in position and landscape orientation
//        let size = uxn.screenSize()
//        print(bgRenderView.frame, bgRenderView.layer.frame, size)
//        bgRenderView.layer.bounds = CGRect(origin: .zero, size: size)
//        fgRenderView.layer.bounds = CGRect(origin: .zero, size: size)
    }

    deinit {
        stopRenderLoop()
    }

    // MARK: - Render Loop

    var displayLink: CADisplayLink?

    func startRenderLoop() {
        let displaylink = CADisplayLink(target: self, selector: #selector(renderLoopDidFire))
        displaylink.add(to: .current, forMode: RunLoop.Mode.default)
        self.displayLink = displaylink
    }

    func stopRenderLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc func renderLoopDidFire(_ displayLink: CADisplayLink) {
        uxn.redraw()

        bgRenderView.layer.contents = uxn.bgImageRef
        fgRenderView.layer.contents = uxn.fgImageRef
    }

    // MARK: - Input

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard sender.view != nil else { return }

        if sender.state == .began {
            let point = sender.location(in: sender.view)
            uxn.domouse(point, touchdown: true)
        } else if sender.state == .ended {
            let point = sender.location(in: sender.view)
            uxn.domouse(point, touchdown: false)
        }
    }

}
