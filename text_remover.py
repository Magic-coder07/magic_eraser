import os
import cv2
import easyocr
import numpy as np
import matplotlib.pyplot as plt

_reader = None


def _get_reader(langs=None):
    global _reader
    if _reader is None:
        _reader = easyocr.Reader(langs or ["en"])
    return _reader


def _build_mask(img: np.ndarray, padding: int = 8):
    reader = _get_reader()
    results = reader.readtext(img)
    mask = np.zeros(img.shape[:2], dtype="uint8")
    mask_blurred = mask.copy()

    for (bbox, text, prob) in results:
        x_coords = [int(p[0]) for p in bbox]
        y_coords = [int(p[1]) for p in bbox]
        x_min, x_max = max(0, min(x_coords) - padding), min(img.shape[1], max(x_coords) + padding)
        y_min, y_max = max(0, min(y_coords) - padding), min(img.shape[0], max(y_coords) + padding)
        cv2.rectangle(mask, (x_min, y_min), (x_max, y_max), 255, -1)
        mask_blurred = cv2.GaussianBlur(mask, (0, 0), 6)

    return results, mask, mask_blurred


def smooth_inpaint(image: np.ndarray, mask: np.ndarray, radius: int = 7) -> np.ndarray:
    result = image.copy()
    if mask.dtype != np.uint8:
        mask = mask.astype(np.uint8)
    kernel = np.ones((3, 3), np.uint8)
    mask_dilated = cv2.dilate(mask, kernel, iterations=2)
    mask_blurred = cv2.GaussianBlur(mask_dilated, (0, 0), 6)
    mask_blurred = cv2.normalize(mask_blurred, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)
    _, mask_binary = cv2.threshold(mask_blurred, 127, 255, cv2.THRESH_BINARY)
    return cv2.inpaint(result, mask_binary, radius, cv2.INPAINT_TELEA)


def edge_aware_inpainting(image: np.ndarray, mask: np.ndarray) -> np.ndarray:
    edges = cv2.Canny(image, 50, 150)
    combined_mask = cv2.bitwise_or(mask, edges)
    combined_mask = cv2.GaussianBlur(combined_mask, (0, 0), 6)
    _, binary_mask = cv2.threshold(combined_mask, 127, 255, cv2.THRESH_BINARY)
    return cv2.inpaint(image, binary_mask, 5, cv2.INPAINT_TELEA)


def post_process_smooth(image: np.ndarray, iterations: int = 2) -> np.ndarray:
    result = image.copy()
    for _ in range(iterations):
        result = cv2.bilateralFilter(result, 5, 50, 50)
    return result


def remove_text_from_image(image_path: str, output_prefix: str = "img_text_removed", padding: int = 8, show_results: bool = True) -> dict:
    if not os.path.exists(image_path):
        raise FileNotFoundError(f"Image not found: {image_path}")

    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"Unable to open image: {image_path}")

    results, mask, mask_blurred = _build_mask(img, padding=padding)
    if len(results) == 0:
        raise ValueError("No text regions detected.")

    inpainted_standard = cv2.inpaint(img, mask_blurred, 5, cv2.INPAINT_TELEA)
    inpainted_smooth = smooth_inpaint(img, mask, radius=7)
    inpainted_edge = edge_aware_inpainting(img, mask)
    final_result = post_process_smooth(inpainted_smooth)

    out_standard = f"{output_prefix}_standard.jpg"
    out_smooth = f"{output_prefix}_smooth.jpg"
    out_edge = f"{output_prefix}_edge.jpg"
    out_final = f"{output_prefix}_final.jpg"

    cv2.imwrite(out_standard, inpainted_standard)
    cv2.imwrite(out_smooth, inpainted_smooth)
    cv2.imwrite(out_edge, inpainted_edge)
    cv2.imwrite(out_final, final_result)

    if show_results:
        plt.figure(figsize=(15, 10))
        plt.subplot(2, 2, 1)
        plt.imshow(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
        plt.title("Original")
        plt.axis("off")

        plt.subplot(2, 2, 2)
        plt.imshow(mask_blurred, cmap="gray")
        plt.title("Blurred Mask")
        plt.axis("off")

        plt.subplot(2, 2, 3)
        plt.imshow(cv2.cvtColor(inpainted_smooth, cv2.COLOR_BGR2RGB))
        plt.title("Smooth Inpainting")
        plt.axis("off")

        plt.subplot(2, 2, 4)
        plt.imshow(cv2.cvtColor(final_result, cv2.COLOR_BGR2RGB))
        plt.title("Final Result")
        plt.axis("off")
        plt.tight_layout()
        plt.show()

    return {
        "standard": out_standard,
        "smooth": out_smooth,
        "edge": out_edge,
        "final": out_final,
        "text_regions": len(results),
    }


if __name__ == "__main__":
    result = remove_text_from_image("og2.jpg", show_results=True)
    print("Saved results:", result)
