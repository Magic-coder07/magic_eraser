import os
from PIL import Image, ImageEnhance

def auto_enhance(image_path, strength=1.0, output_path=None):
    """Auto enhance an image"""
    img = Image.open(image_path).convert("RGB")
    img = ImageEnhance.Brightness(img).enhance(1.0 + 0.15 * strength)
    img = ImageEnhance.Contrast(img).enhance(1.0 + 0.25 * strength)
    img = ImageEnhance.Color(img).enhance(1.0 + 0.20 * strength)
    img = ImageEnhance.Sharpness(img).enhance(1.0 + 0.40 * strength)
    
    if not output_path:
        name, ext = os.path.splitext(image_path)
        output_path = f"{name}_enhanced{ext}"
    
    img.save(output_path, quality=95)
    return output_path

# Usage
if __name__ == "__main__":
    result = auto_enhance("blur.jpg", strength=1.2)
    print(f"Saved: {result}")