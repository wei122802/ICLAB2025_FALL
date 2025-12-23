import pandas as pd
import numpy as np

# ==========================================
#  Path Generation Functions (Zigzag/Morton)
# ==========================================

def generate_zigzag_path(n):
    """ Generates a list of (r, c) coordinates for an n x n Zigzag path. """
    result = []
    for i in range(2 * n - 1):
        if i % 2 == 0:
            # Upwards
            r = i if i < n else n - 1
            c = 0 if i < n else i - n + 1
            while r >= 0 and c < n:
                result.append((r, c))
                r -= 1
                c += 1
        else:
            # Downwards
            r = 0 if i < n else i - n + 1
            c = i if i < n else n - 1
            while r < n and c >= 0:
                result.append((r, c))
                r += 1
                c -= 1
    return result

def generate_morton_path(n):
    """ Generates a list of (r, c) coordinates for an n x n Morton (Z-order) path. """
    path = []
    num_pixels = n * n
    for k in range(num_pixels):
        r = 0
        c = 0
        # De-interleave bits to map linear index k to (r, c)
        # k bits: ... r2 c2 r1 c1 r0 c0
        for b in range(16): # 16 bits is sufficient for 16x16
             if (k >> (2*b)) & 1:
                 c |= (1 << b)
             if (k >> (2*b + 1)) & 1:
                 r |= (1 << b)
        path.append((r, c))
    return path

# ==========================================
#  Transformation Functions
# ==========================================

def transform_mx(img):
    return np.flipud(img)

def transform_my(img):
    return np.fliplr(img)

def transform_trp(img):
    return img.T

def transform_strp(img):
    # Secondary Transpose: Reflect along secondary diagonal
    n = img.shape[0]
    new_img = np.zeros_like(img)
    for r in range(n):
        for c in range(n):
            new_img[r, c] = img[n-1-c, n-1-r]
    return new_img

def transform_r90(img):
    return np.rot90(img, k=-1) # CW

def transform_r180(img):
    return np.rot90(img, k=2)

def transform_r270(img):
    return np.rot90(img, k=1) # CCW = 270 CW

def transform_rs(img, shift=5):
    n = img.shape[0]
    new_img = np.zeros_like(img)
    # Valid part
    new_img[:, shift:] = img[:, :-shift]
    # Mirror Padding
    for c in range(shift):
        src_idx = (shift - 1) - c
        new_img[:, c] = img[:, src_idx]
    return new_img

def transform_ls(img, shift=5):
    n = img.shape[0]
    new_img = np.zeros_like(img)
    # Valid part
    new_img[:, :-shift] = img[:, shift:]
    # Mirror Padding
    for c in range(n - shift, n):
        diff = c - (n - shift)
        src_idx = (n - 1) - diff
        new_img[:, c] = img[:, src_idx]
    return new_img

def transform_us(img, shift=5):
    n = img.shape[0]
    new_img = np.zeros_like(img)
    # Valid part
    new_img[:-shift, :] = img[shift:, :]
    # Mirror Padding
    for r in range(n - shift, n):
        diff = r - (n - shift)
        src_idx = (n - 1) - diff
        new_img[r, :] = img[src_idx, :]
    return new_img

def transform_ds(img, shift=5):
    n = img.shape[0]
    new_img = np.zeros_like(img)
    # Valid part
    new_img[shift:, :] = img[:-shift, :]
    # Mirror Padding
    for r in range(shift):
        src_idx = (shift - 1) - r
        new_img[r, :] = img[src_idx, :]
    return new_img

def transform_reorder(img, block_size, path_func):
    """
    Applies reordering based on the path function.
    Logic: Dest[Raster_Order] = Src[Path_Order]
    """
    n = img.shape[0]
    new_img = np.zeros_like(img)
    path = path_func(block_size)
    
    # Iterate through each block
    for br in range(0, n, block_size):
        for bc in range(0, n, block_size):
            src_block = img[br:br+block_size, bc:bc+block_size]
            dst_block = np.zeros_like(src_block)
            
            # Apply mapping
            for k, (pr, pc) in enumerate(path):
                # k is the raster index in the destination block
                dr, dc = divmod(k, block_size)
                # Map: The k-th pixel in raster order of Dest gets the pixel from (pr, pc) of Src
                dst_block[dr, dc] = src_block[pr, pc]
                
            new_img[br:br+block_size, bc:bc+block_size] = dst_block
    return new_img

# ==========================================
#  Main Execution
# ==========================================

# 1. Create Source 16x16 Image (Values 0 to 255)
source = np.arange(256).reshape((16, 16))

# 2. Generate Results Dictionary
results = {}
results['Source'] = source
results['MX']   = transform_mx(source)
results['MY']   = transform_my(source)
results['TRP']  = transform_trp(source)
results['STRP'] = transform_strp(source)
results['R90']  = transform_r90(source)
results['R180'] = transform_r180(source)
results['R270'] = transform_r270(source)
results['RS']   = transform_rs(source, 5)
results['LS']   = transform_ls(source, 5)
results['US']   = transform_us(source, 5)
results['DS']   = transform_ds(source, 5)

results['ZZ4'] = transform_reorder(source, 4, generate_zigzag_path)
results['ZZ8'] = transform_reorder(source, 8, generate_zigzag_path)
results['MO4'] = transform_reorder(source, 4, generate_morton_path)
results['MO8'] = transform_reorder(source, 8, generate_morton_path)

# 3. Write to Excel
output_file = 'Lab11_16x16_Examples.xlsx'
print(f"Generating {output_file} ...")
with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
    for name, matrix in results.items():
        # Convert to DataFrame for easier Excel writing
        df = pd.DataFrame(matrix)
        df.to_excel(writer, sheet_name=name, header=False, index=False)

print("Done! File generated successfully.")

