import os
from rembg import remove, new_session
from PIL import Image

OUTPUT_DIR = "bg_removed"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def remove_bg_transparent(image_path: str) -> str:
    """Remove background and save as transparent PNG"""
    # Check if file exists
    if not os.path.exists(image_path):
        raise FileNotFoundError(f"Image not found: {image_path}")
    
    # Remove background
    session = new_session("u2net")
    with open(image_path, "rb") as f:
        result = remove(f.read(), session=session)
    
    # Save result
    out_path = os.path.join(OUTPUT_DIR, "transparent.png")
    with open(out_path, "wb") as f:
        f.write(result)
    
    print(f"✓ Background removed! Saved to: {out_path}")
    return out_path

if __name__ == "__main__":
    # Change this to your image filename
    input_image = "BD.jpg"
    
    try:
        remove_bg_transparent(input_image)
        print("Done!")
    except FileNotFoundError as e:
        print(f"Error: {e}")
        print("Please make sure the image file exists.")