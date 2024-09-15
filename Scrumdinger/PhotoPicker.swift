import SwiftUI
import PhotosUI

enum ImageFormat {
    case JPEG
    case PNG
    case Other
    case Error
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedImageFormat: ImageFormat?
    let compressionQuality = CGFloat(0.8);

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                guard let url = url else {
                    self.parent.selectedImageFormat = .Error
                    return
                }
                
                DispatchQueue.main.async {
                    let urlString = url.standardizedFileURL.absoluteString.lowercased()
                    if urlString.hasSuffix("jpeg") || urlString.hasSuffix("jpg") {
                        self.parent.selectedImageFormat = .JPEG
                    } else if urlString.hasSuffix("png") {
                        self.parent.selectedImageFormat = .PNG
                    } else {
                        self.parent.selectedImageFormat = .Other
                    }
                }
            }

            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self.parent.selectedImage = self.parent.compressImage(uiImage)
                    }
                }
            }
        }
    }
    
    // Function to compress the image
    func compressImage(_ image: UIImage) -> UIImage? {
        guard let compressedData = image.jpegData(compressionQuality: compressionQuality) else {
            print("couldn't compress image!")
            return nil
        }

        guard let jpegBefore = image.jpegData(compressionQuality: CGFloat(1.0)) else {
            print("couldn't get jpeg data")
            return nil
        }

        let sizeBefore = jpegBefore.count
        let sizeAfter = compressedData.count
        let reduction = Float(sizeAfter) / Float(sizeBefore)
        print("compressed image, before:", jpegBefore.count, "after:", compressedData.count, "size:", reduction, "%")
        return UIImage(data: compressedData)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No need to update anything
    }
}
