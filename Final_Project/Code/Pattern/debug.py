import numpy as np
import sys
import os  # [新增] 用於處理路徑

# ==========================================
# 0. Global Configuration
# ==========================================
# 設定讀取/寫入的 Pattern 資料夾名稱
NUM_PATTERNS = 1500
BASE_DATA_DIR = "data"
# 自動組合成: data/100
TARGET_DIR = os.path.join(BASE_DATA_DIR, str(NUM_PATTERNS))

# ==========================================
#  Color & Formatting Helpers
# ==========================================
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m' 
    RESET = '\033[0m'
    BOLD = '\033[1m'

# ==========================================
#  Core Logic (Shared by All Options)
# ==========================================
IMG_SIZE = 128
FIR_COEFFS = [1, -5, 20, 20, -5, 1]
H = np.array([
    [1,  1,  1,  1],
    [1, -1,  1, -1],
    [1,  1, -1, -1],
    [1, -1, -1,  1]
])

def clip(x, min_val, max_val):
    return max(min_val, min(x, max_val))

def get_pixel(img, y, x):
    y_clamped = clip(y, 0, IMG_SIZE - 1)
    x_clamped = clip(x, 0, IMG_SIZE - 1)
    return int(img[y_clamped, x_clamped])

def fir_filter_interpolation(img, center_y, center_x, frac_y, frac_x):
    if frac_y == 0 and frac_x == 0:
        return get_pixel(img, center_y, center_x)
    elif frac_y == 0 and frac_x == 1:
        val = 0
        offsets = [-2, -1, 0, 1, 2, 3]
        for i, offset in enumerate(offsets):
            val += get_pixel(img, center_y, center_x + offset) * FIR_COEFFS[i]
        return clip((val + 16) >> 5, 0, 255)
    elif frac_y == 1 and frac_x == 0:
        val = 0
        offsets = [-2, -1, 0, 1, 2, 3]
        for i, offset in enumerate(offsets):
            val += get_pixel(img, center_y + offset, center_x) * FIR_COEFFS[i]
        return clip((val + 16) >> 5, 0, 255)
    elif frac_y == 1 and frac_x == 1:
        temp_vals = []
        vert_offsets = [-2, -1, 0, 1, 2, 3]
        horz_offsets = [-2, -1, 0, 1, 2, 3]
        for v_off in vert_offsets:
            row_val = 0
            curr_y = center_y + v_off
            for i, h_off in enumerate(horz_offsets):
                row_val += get_pixel(img, curr_y, center_x + h_off) * FIR_COEFFS[i]
            temp_vals.append(row_val)
        final_val = 0
        for i in range(6):
            final_val += temp_vals[i] * FIR_COEFFS[i] 
        return clip((final_val + 512) >> 10, 0, 255)
    return 0

def get_interpolated_block(img, raw_val_x, raw_val_y, size, name, verbose=True):
    mv_x_int = raw_val_x >> 1
    mv_x_frac = raw_val_x & 1
    mv_y_int = raw_val_y >> 1
    mv_y_frac = raw_val_y & 1
    if verbose:
        print(f"{Colors.YELLOW}  > Generating {name} {size}x{size} Block... (Center: {mv_x_int}, {mv_y_int}){Colors.RESET}")
    
    block = np.zeros((size, size), dtype=int)
    for y in range(size):
        for x in range(size):
            val = fir_filter_interpolation(img, mv_y_int + y, mv_x_int + x, mv_y_frac, mv_x_frac)
            block[y, x] = val
    return block

# --- SATD Calculation (Pure Sum) for Golden Gen ---
def calculate_satd_8x8(block_diff):
    total_satd = 0
    for r in range(0, 8, 4):
        for c in range(0, 8, 4):
            sub_block = block_diff[r:r+4, c:c+4]
            temp = np.dot(H, sub_block)
            Y = np.dot(temp, H.T)
            total_satd += np.sum(np.abs(Y))
    return int(total_satd)

# --- Detailed SATD for Debug (With Print) ---
def calculate_satd_detailed(block_diff, search_idx):
    total_satd = 0
    sub_indices = [(0,0), (0,4), (4,0), (4,4)]
    perm_order = [0, 2, 3, 1]
    
    print(f"{Colors.HEADER}=== Search Point {search_idx} Details ==={Colors.RESET}")
    
    for idx, (r, c) in enumerate(sub_indices):
        sub_block = block_diff[r:r+4, c:c+4]
        temp = np.dot(H, sub_block)
        Y = np.dot(temp, H.T)
        abs_Y = np.abs(Y)
        sub_satd = np.sum(abs_Y)
        total_satd += sub_satd
        
        display_Y = abs_Y[:, perm_order][perm_order, :]
        
        print(f"{Colors.CYAN}  > Sub-block {idx} (Top-Left: {r},{c}){Colors.RESET}")
        for row in display_Y:
            print("    [", end="")
            for val in row:
                print(f"{val:4d}", end=" ")
            print("]")
        print(f"    {Colors.YELLOW}Sum (Sub-SATD): {sub_satd}{Colors.RESET}\n")
            
    print(f"  {Colors.BOLD}{Colors.GREEN}Total SATD for SP {search_idx}: {total_satd}{Colors.RESET}\n")
    return int(total_satd)

def print_matrix(name, matrix, color=Colors.CYAN):
    print(f"{color}{name}:{Colors.RESET}")
    rows, cols = matrix.shape
    for r in range(rows):
        print("  [", end="")
        for c in range(cols):
            val = matrix[r, c]
            print(f"{val:5d}", end=" ")
        print("]")
    print()

def print_raw_region(img, raw_cx, raw_cy, img_name="Image"):
    cx = raw_cx >> 1
    cy = raw_cy >> 1
    frac_x = raw_cx & 1
    frac_y = raw_cy & 1
    
    offset_x = 2 if frac_x == 1 else 0
    offset_y = 2 if frac_y == 1 else 0
    
    start_x = cx - offset_x
    start_y = cy - offset_y
    window_size = 15
    
    if frac_x == 0 and frac_y == 0: mode_str = "Integer Position"
    elif frac_x == 1 and frac_y == 0: mode_str = "Horizontal Interp (X-2)"
    elif frac_x == 0 and frac_y == 1: mode_str = "Vertical Interp (Y-2)"
    else: mode_str = "2D Separable (X-2, Y-2)"

    print(f"\n{Colors.HEADER}--- Inspecting {img_name} Region (15x15) ---{Colors.RESET}")
    print(f"{Colors.YELLOW}Mode: {mode_str}{Colors.RESET}")
    print(f"Raw Input: ({raw_cx}, {raw_cy}) | Integer Center: ({cx}, {cy})")
    
    print("      ", end="")
    for i in range(window_size):
        curr_x = start_x + i
        if curr_x < 0 or curr_x >= IMG_SIZE:
            print(f"{Colors.RED}{curr_x:4d}{Colors.RESET}", end="")
        else:
            print(f"{curr_x:4d}", end="")
    print()
    print("      " + "-" * (window_size * 4))

    for r in range(window_size):
        curr_y = start_y + r
        if curr_y < 0 or curr_y >= IMG_SIZE:
            print(f"{Colors.RED}{curr_y:4d}{Colors.RESET} |", end="")
        else:
            print(f"{curr_y:4d} |", end="")

        for c in range(window_size):
            curr_x = start_x + c
            val = get_pixel(img, curr_y, curr_x)
            is_center = (curr_x == cx and curr_y == cy)
            is_oob = (curr_x < 0 or curr_x >= IMG_SIZE or curr_y < 0 or curr_y >= IMG_SIZE)
            
            if is_center:
                print(f"{Colors.GREEN}{Colors.BOLD}{val:4X}{Colors.RESET}", end="")
            elif is_oob:
                print(f"{Colors.RED}{val:4X}{Colors.RESET}", end="")
            else:
                print(f"{val:4X}", end="")
        print()
    print()

# ==========================================
#  File Loading & Golden Gen Logic
# ==========================================

def load_L_matrices(filename):
    try:
        with open(filename, 'r') as f:
            data = f.read().split()
        values = [int(x) for x in data]
        images = []
        num_pixels = 128 * 128
        for i in range(0, len(values), num_pixels):
            img_flat = values[i : i + num_pixels]
            if len(img_flat) == num_pixels:
                images.append(np.array(img_flat).reshape(128, 128))
        return images
    except FileNotFoundError:
        print(f"{Colors.RED}Error: {filename} not found in {TARGET_DIR}!{Colors.RESET}")
        sys.exit()

def load_MV_corrected(filename):
    try:
        with open(filename, 'r') as f:
            data = f.read().split()
        values = [int(x, 16) for x in data]
        instructions = []
        for i in range(0, len(values), 8):
            if i + 8 <= len(values):
                instructions.append(values[i : i+8])
        return instructions
    except FileNotFoundError:
        print(f"{Colors.RED}Error: {filename} not found in {TARGET_DIR}!{Colors.RESET}")
        sys.exit()

# Core Calculation Function (Used by Option 4)
def process_single_search_set(L0_img, L1_img, coords):
    # 1. Generate 10x10 Blocks
    block_l0_10x10 = get_interpolated_block(L0_img, coords[0], coords[1], 10, "L0", verbose=False)
    block_l1_10x10 = get_interpolated_block(L1_img, coords[2], coords[3], 10, "L1", verbose=False)
    
    min_satd = float('inf')
    best_idx = -1
    search_cnt = 0
    
    # 2. Search 9 Points (Column-Major Order: 0,0 -> 1,0 -> 2,0 -> 0,1 ...)
    for x_off in range(3):
        for y_off in range(3):
            
            # Mirror Logic
            l0_start_y, l0_start_x = y_off, x_off
            l1_start_y, l1_start_x = 2-y_off, 2-x_off
            
            sub_l0 = block_l0_10x10[l0_start_y : l0_start_y+8, l0_start_x : l0_start_x+8]
            sub_l1 = block_l1_10x10[l1_start_y : l1_start_y+8, l1_start_x : l1_start_x+8]
            
            diff = sub_l0.astype(int) - sub_l1.astype(int)
            
            # Calculate Sum Only (No print)
            curr_satd = calculate_satd_8x8(diff)
            
            if curr_satd < min_satd:
                min_satd = curr_satd
                best_idx = search_cnt
            
            search_cnt += 1
            
    return {'idx': best_idx, 'satd': min_satd}

def generate_golden_file(L0_list, L1_list, MV_data):
    instructions_per_pattern = 64
    num_patterns = len(L0_list)
    
    # [Modify] 組合成目標路徑 data/100/output_golden.txt
    out_file_path = os.path.join(TARGET_DIR, "output_golden.txt")
    
    print(f"{Colors.CYAN}Generating golden file at: {out_file_path}{Colors.RESET}")
    print(f"{Colors.YELLOW}(Using Logic: Column-Major Search, Mirror Matching, 10x10 Buffer){Colors.RESET}")
    
    with open(out_file_path, "w") as f_out:
        for p in range(num_patterns):
            print(f"  Processing Pattern {p}...")
            l0 = L0_list[p]
            l1 = L1_list[p]
            
            start_idx = p * instructions_per_pattern
            end_idx = start_idx + instructions_per_pattern
            
            if start_idx >= len(MV_data): break
            current_mvs = MV_data[start_idx : end_idx]
            
            for mv_tuple in current_mvs:
                # Point 1 (Bytes 0-3)
                p1_res = process_single_search_set(l0, l1, mv_tuple[0:4])
                # Point 2 (Bytes 4-7)
                p2_res = process_single_search_set(l0, l1, mv_tuple[4:8])
                
                # Pack: P2_IDX | P2_SATD | P1_IDX | P1_SATD
                packed_val = (p2_res['idx'] << 52) | (p2_res['satd'] << 28) | \
                             (p1_res['idx'] << 24) | (p1_res['satd'])
                f_out.write(f"{packed_val:014X}\n")
                
    print(f"{Colors.GREEN}{Colors.BOLD}Done! output_golden.txt generated in {TARGET_DIR}.{Colors.RESET}")

# ==========================================
#  Main Loop
# ==========================================
if __name__ == "__main__":
    
    # [New] 確認資料夾是否存在
    if not os.path.exists(TARGET_DIR):
        print(f"{Colors.RED}Error: Directory {TARGET_DIR} does not exist.{Colors.RESET}")
        print("Please run the generator script first.")
        sys.exit()

    print(f"{Colors.BOLD}Loading Data from: {TARGET_DIR}{Colors.RESET}")
    
    # [Modify] 使用 os.path.join 讀取目標資料夾下的檔案
    try:
        L0_list = load_L_matrices(os.path.join(TARGET_DIR, "L0.txt")) 
        L1_list = load_L_matrices(os.path.join(TARGET_DIR, "L1.txt")) 
        MV_data_all = load_MV_corrected(os.path.join(TARGET_DIR, "MV.txt"))
    except FileNotFoundError:
        print(f"Error: Input files not found in {TARGET_DIR}.")
        sys.exit()
        
    print(f"{Colors.GREEN}Loaded {len(L0_list)} patterns and {len(MV_data_all)} MV instructions.{Colors.RESET}\n")

    while True:
        print(f"{Colors.HEADER}========================================{Colors.RESET}")
        print(f"{Colors.HEADER}      Verilog Master Debugger v5.1      {Colors.RESET}")
        print(f"{Colors.HEADER}========================================{Colors.RESET}")
        print("1. Debug Full Process (Mirror Matching & Permuted SATD)")
        print("2. Inspect Raw Image Region (15x15)")
        print("3. Show Interpolated 10x10 Blocks Only")
        print("4. Generate output_golden.txt (Full Run)")
        print("q. Quit")
        
        choice = input("Select Option: ")
        
        if choice.lower() == 'q': break
        
        # --- OPTION 4: Generate Golden File ---
        if choice == '4':
            generate_golden_file(L0_list, L1_list, MV_data_all)
            continue

        # --- Common Pattern Selection for 1, 2, 3 ---
        try:
            pat_idx_str = input("Enter Pattern Index (0-9): ")
            pat_idx = int(pat_idx_str)
            if pat_idx < 0 or pat_idx >= len(L0_list):
                print(f"{Colors.RED}Invalid Index!{Colors.RESET}")
                continue
            img_l0 = L0_list[pat_idx]
            img_l1 = L1_list[pat_idx]
        except ValueError:
            print("Invalid number.")
            continue

        # Option 1 or 3
        if choice == '1' or choice == '3':
            print(f"{Colors.GREEN}Selected Pattern {pat_idx}.{Colors.RESET}")
            print("Enter coordinates as RAW VALUES (Int << 1 | Frac).")
            try:
                raw_l0_x = int(input("L0 MV X (raw): "))
                raw_l0_y = int(input("L0 MV Y (raw): "))
                raw_l1_x = int(input("L1 MV X (raw): "))
                raw_l1_y = int(input("L1 MV Y (raw): "))
                
                print("\n" + "-"*40)
                
                # Pre-calculate 10x10
                block_l0_10x10 = get_interpolated_block(img_l0, raw_l0_x, raw_l0_y, 10, "L0")
                block_l1_10x10 = get_interpolated_block(img_l1, raw_l1_x, raw_l1_y, 10, "L1")
                
                if choice == '3':
                    print_matrix("L0 Interpolated (10x10)", block_l0_10x10, Colors.CYAN)
                    print_matrix("L1 Interpolated (10x10)", block_l1_10x10, Colors.CYAN)
                
                elif choice == '1':
                    print_matrix("L0 Interpolated (10x10)", block_l0_10x10, Colors.CYAN)
                    print_matrix("L1 Interpolated (10x10)", block_l1_10x10, Colors.CYAN)
                    
                    print(f"{Colors.HEADER}--- Starting Mirror MVD Matching (9 Points) ---{Colors.RESET}")
                    
                    min_satd = float('inf')
                    best_search_idx = -1
                    search_idx = 0
                    
                    # Column-Major Loop (Outer X, Inner Y)
                    for x_off in range(3):
                        for y_off in range(3):
                            
                            l0_start_y, l0_start_x = y_off, x_off
                            l1_start_y, l1_start_x = 2-y_off, 2-x_off
                            
                            sub_l0 = block_l0_10x10[l0_start_y : l0_start_y+8, l0_start_x : l0_start_x+8]
                            sub_l1 = block_l1_10x10[l1_start_y : l1_start_y+8, l1_start_x : l1_start_x+8]
                            
                            diff = sub_l0.astype(int) - sub_l1.astype(int)
                            
                            print(f"{Colors.YELLOW}Search Point {search_idx} | L0({y_off},{x_off}) vs L1({2-y_off},{2-x_off}){Colors.RESET}")
                            
                            curr_satd = calculate_satd_detailed(diff, search_idx)
                            
                            if curr_satd < min_satd:
                                min_satd = curr_satd
                                best_search_idx = search_idx
                            
                            search_idx += 1
                    
                    print("-" * 40)
                    print(f"{Colors.GREEN}{Colors.BOLD}🏆 WINNER: Search Point {best_search_idx}{Colors.RESET}")
                    print(f"{Colors.GREEN}{Colors.BOLD}🏆 Minimum SATD: {min_satd}{Colors.RESET}")
                    print("-" * 40)
                    
            except ValueError:
                print("Invalid input.")

        # Option 2
        elif choice == '2':
            img_choice = input("Select Image (0 for L0, 1 for L1): ")
            target_img = img_l0 if img_choice == '0' else img_l1
            img_name = "L0" if img_choice == '0' else "L1"
            print("Enter CENTER RAW VALUES (Int << 1 | Frac).")
            try:
                raw_cx = int(input("Center X (Raw): "))
                raw_cy = int(input("Center Y (Raw): "))
                print_raw_region(target_img, raw_cx, raw_cy, img_name)
            except ValueError:
                print("Invalid integer.")