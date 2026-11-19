import UIKit
import PhotosUI

/// Sélection système : accès uniquement à l'image choisie, sans lire toute la photothèque.
final class PhotoPickerCoordinator: NSObject, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private weak var owner: UIViewController?
    private let selection: (UIImage) -> Void
    init(owner: UIViewController, selection: @escaping (UIImage) -> Void) {
        self.owner = owner; self.selection = selection
    }
    func present(from source: UIView? = nil) {
        guard let owner else { return }
        let menu = UIAlertController(title: "Ajouter une photo", message: nil, preferredStyle: .actionSheet)
        menu.addAction(UIAlertAction(title: "Choisir dans la photothèque", style: .default) { [weak self] _ in self?.showLibrary() })
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            menu.addAction(UIAlertAction(title: "Prendre une photo", style: .default) { [weak self] _ in
                guard let self else { return }
                let camera = UIImagePickerController()
                camera.sourceType = .camera; camera.delegate = self
                self.owner?.present(camera, animated: true)
            })
        }
        menu.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        menu.popoverPresentationController?.sourceView = source ?? owner.view
        menu.popoverPresentationController?.sourceRect = source?.bounds ?? CGRect(x: owner.view.bounds.midX, y: owner.view.bounds.midY, width: 1, height: 1)
        owner.present(menu, animated: true)
    }
    private func showLibrary() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images; configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        owner?.present(picker, animated: true)
    }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
            picker.dismiss(animated: true); return
        }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                picker.dismiss(animated: true) {
                    guard let self else { return }
                    if let image = object as? UIImage { self.selection(self.normalized(image)) }
                    else { self.showError() }
                }
            }
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            if let image { self.selection(self.normalized(image)) } else { self.showError() }
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    private func normalized(_ image: UIImage) -> UIImage {
        let scale = min(1, 1600 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
    private func showError() {
        let alert = UIAlertController(title: "Photo indisponible", message: "Impossible de lire cette image. Essaie avec une autre photo.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        owner?.present(alert, animated: true)
    }
}
