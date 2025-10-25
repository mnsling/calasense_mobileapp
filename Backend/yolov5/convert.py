import os
import cv2
import numpy as np
from tqdm import tqdm
import shutil

# -----------------------------
# Conversion functions
# -----------------------------

def rgb_to_ycbcr_channels(image):
    """Manual Y, Cb, Cr conversion (paper formulas)."""
    rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB).astype(np.float32)
    R, G, B = rgb[:,:,0], rgb[:,:,1], rgb[:,:,2]

    Y  = 0.299*R + 0.587*G + 0.114*B
    Cb = 0.564*(B - Y) + 128
    Cr = 0.713*(R - Y) + 128

    Y  = np.clip(Y,  0, 255).astype(np.uint8)
    Cb = np.clip(Cb, 0, 255).astype(np.uint8)
    Cr = np.clip(Cr, 0, 255).astype(np.uint8)

    return Y, Cb, Cr

def rgb_to_hsi_channels(image):
    """Manual H, S, I conversion (paper formulas)."""
    rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
    R, G, B = rgb[:,:,0], rgb[:,:,1], rgb[:,:,2]

    # Intensity
    I = (R + G + B) / 3.0

    # Saturation
    min_val = np.minimum(np.minimum(R, G), B)
    S = 1 - (3 / (R + G + B + 1e-6)) * min_val

    # Hue
    num = 0.5 * ((R - G) + (R - B))
    den = np.sqrt((R - G)**2 + (R - B)*(G - B)) + 1e-6
    theta = np.arccos(np.clip(num / den, -1, 1))

    H = np.where(B <= G, theta, 2*np.pi - theta)
    H = H / (2*np.pi)  # normalize to [0,1]

    # Scale back to [0,255]
    H = np.clip(H * 255, 0, 255).astype(np.uint8)
    S = np.clip(S * 255, 0, 255).astype(np.uint8)
    I = np.clip(I * 255, 0, 255).astype(np.uint8)

    return H, S, I

def rgb_to_lab_channels(image):
    """Convert BGR image to Lab channels."""
    lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
    L, a, b = cv2.split(lab)
    return L, a, b
# -----------------------------
# Wrapper: pick channel
# -----------------------------
def convert_image(image, channel="Cr"):
    """Convert image to the selected channel and replicate to 3-channels for YOLO."""
    if channel in ["Y", "Cb", "Cr"]:
        Y, Cb, Cr = rgb_to_ycbcr_channels(image)
        mapping = {"Y": Y, "Cb": Cb, "Cr": Cr}
        out = mapping[channel]
    elif channel in ["H", "S", "I"]:
        H, S, I = rgb_to_hsi_channels(image)
        mapping = {"H": H, "S": S, "I": I}
        out = mapping[channel]
    elif channel in ["R", "G", "B"]:
        rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        R, G, B = cv2.split(rgb)
        mapping = {"R": R, "G": G, "B": B}
        out = mapping[channel]
    elif channel in ["L", "a", "b"]:
        L, a_ch, b_ch = rgb_to_lab_channels(image)
        mapping = {"L": L, "a": a_ch, "b": b_ch}
        out = mapping[channel]
    else:
        raise ValueError("Unsupported channel. Choose from Y, Cb, Cr, H, S, I, R, G, B, L, a, b.")

    # Replicate to 3 channels for YOLO
    out_3ch = cv2.merge([out, out, out])
    return out_3ch

# -----------------------------
# Dataset Conversion
# -----------------------------
def convert_dataset(dataset_path, output_path, channel="Cr"):
    if os.path.exists(output_path):
        shutil.rmtree(output_path)

    # Copy labels only, recreate structure
    for split in ["train", "valid", "test"]:
        os.makedirs(os.path.join(output_path, split, "images"), exist_ok=True)
        shutil.copytree(
            os.path.join(dataset_path, split, "labels"),
            os.path.join(output_path, split, "labels")
        )

    # Process images
    for split in ["train", "valid", "test"]:
        img_dir = os.path.join(dataset_path, split, "images")
        out_dir = os.path.join(output_path, split, "images")

        for img_name in tqdm(os.listdir(img_dir), desc=f"Processing {split}-{channel}"):
            img_path = os.path.join(img_dir, img_name)
            img = cv2.imread(img_path)
            if img is None:
                continue

            converted = convert_image(img, channel)
            out_path = os.path.join(out_dir, os.path.splitext(img_name)[0] + ".png")
            cv2.imwrite(out_path, converted)

# -----------------------------
# Example usage
# -----------------------------

    
if __name__ == "__main__":
    DATASET_PATH = "calamansi-augmented-dataset"
    OUTPUT_PATH = "colorspace-datasets/H"  # change name per channel
    convert_dataset(DATASET_PATH, OUTPUT_PATH, channel="H")
    
