import UIKit

class ViewController: UIViewController {

    var uxn: UxnBridge = UxnBridge()

    override func viewDidLoad() {
        super.viewDidLoad()

        let rom = Bundle.main.path(forResource: "screen", ofType: "rom")!
        uxn.load(rom)
    }

    @IBOutlet weak var bgRenderView: UIView!
    @IBOutlet weak var fgRenderView: UIView!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        uxn.redraw()

        bgRenderView.layer.contents = uxn.bgImageRef
        fgRenderView.layer.contents = uxn.fgImageRef

        let size = uxn.screenSize()

        print(bgRenderView.frame, bgRenderView.layer.frame, size)

        bgRenderView.layer.bounds = CGRect(origin: .zero, size: size)
        fgRenderView.layer.bounds = CGRect(origin: .zero, size: size)
    }

}
