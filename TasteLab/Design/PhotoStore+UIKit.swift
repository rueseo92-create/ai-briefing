import UIKit

extension PhotoStore {
    /// 긴 변 1600px로 줄이고 JPEG로 저장한다. UIImage를 다시 인코딩하므로 위치 같은 원본 메타데이터는 남지 않는다.
    func save(_ image: UIImage) -> String? {
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, 1600 / max(longest, 1))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = resized.jpegData(compressionQuality: 0.82) else { return nil }
        return save(jpeg: data)
    }

    func image(named name: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: name).path)
    }
}
