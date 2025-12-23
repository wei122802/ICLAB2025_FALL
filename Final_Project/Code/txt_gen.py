import numpy as np
import os 

# ==========================================
# 1. Global Configuration 
# ==========================================
NUM_PATTERNS = 100
SEED = "Wei122802"

np.random.seed(SEED)

# [SPEC Source: 92] Max value < 117.00, so max integer is 116.
MAX_MV_VAL = 116 

BASE_DIR = "data"

# ==========================================
# 2. Helper Functions
# ==========================================

def get_p2_coord(p1_val):
    """
    Helper to generate Point 2 based on Point 1 constraint (+/- 5).
    FIX: Clamp high to MAX_MV_VAL (116).
    """
    low = max(0, p1_val - 5)
    high = min(MAX_MV_VAL, p1_val + 5) 
    return np.random.randint(low, high + 1)

def generate_corner_cases():
    """
    Generate a list of specific corner cases.
    """
    cases = []
    boundaries = [0, 1, MAX_MV_VAL] 
    frac_combos = [(0,0), (0,1), (1,0), (1,1)] 
    
    for bx in boundaries:
        for by in boundaries:
            for fx, fy in frac_combos:
                case = {
                    'p1_l0_x_int': bx, 'p1_l0_y_int': by, 
                    'p1_l0_x_frac': fx, 'p1_l0_y_frac': fy,
                    'p1_l1_x_int': bx, 'p1_l1_y_int': by, 
                    'p1_l1_x_frac': fx, 'p1_l1_y_frac': fy
                }
                cases.append(case)
    return cases

def generate_mv_data(num_patterns, output_path):
    """
    Generate MV.txt in the specified output_path.
    """
    corner_cases_queue = generate_corner_cases()
    print(f"Prepared {len(corner_cases_queue)} Corner Cases to inject first.")

    file_path = os.path.join(output_path, "MV.txt")

    with open(file_path, "w") as f:
        print(f"Generating MV.txt to {file_path} ...")
        
        for p in range(num_patterns):
            for _ in range(64):
                if len(corner_cases_queue) > 0:
                    c = corner_cases_queue.pop(0)
                    p1_l0_x_int = c['p1_l0_x_int']; p1_l0_y_int = c['p1_l0_y_int']
                    p1_l1_x_int = c['p1_l1_x_int']; p1_l1_y_int = c['p1_l1_y_int']
                    p1_l0_x_frac = c['p1_l0_x_frac']; p1_l0_y_frac = c['p1_l0_y_frac']
                    p1_l1_x_frac = c['p1_l1_x_frac']; p1_l1_y_frac = c['p1_l1_y_frac']
                else:
                    p1_l0_x_int = np.random.randint(0, MAX_MV_VAL + 1)
                    p1_l0_y_int = np.random.randint(0, MAX_MV_VAL + 1)
                    p1_l1_x_int = np.random.randint(0, MAX_MV_VAL + 1)
                    p1_l1_y_int = np.random.randint(0, MAX_MV_VAL + 1)
                    p1_l0_x_frac = np.random.randint(0, 2); p1_l0_y_frac = np.random.randint(0, 2)
                    p1_l1_x_frac = np.random.randint(0, 2); p1_l1_y_frac = np.random.randint(0, 2)

                p2_l0_x_int = get_p2_coord(p1_l0_x_int); p2_l0_y_int = get_p2_coord(p1_l0_y_int)
                p2_l1_x_int = get_p2_coord(p1_l1_x_int); p2_l1_y_int = get_p2_coord(p1_l1_y_int)
                p2_l0_x_frac = np.random.randint(0, 2); p2_l0_y_frac = np.random.randint(0, 2)
                p2_l1_x_frac = np.random.randint(0, 2); p2_l1_y_frac = np.random.randint(0, 2)

                mv_set = [
                    (p1_l0_x_int << 1) | p1_l0_x_frac, (p1_l0_y_int << 1) | p1_l0_y_frac, 
                    (p1_l1_x_int << 1) | p1_l1_x_frac, (p1_l1_y_int << 1) | p1_l1_y_frac, 
                    (p2_l0_x_int << 1) | p2_l0_x_frac, (p2_l0_y_int << 1) | p2_l0_y_frac, 
                    (p2_l1_x_int << 1) | p2_l1_x_frac, (p2_l1_y_int << 1) | p2_l1_y_frac  
                ]
                hex_line = " ".join([f"{val:02X}" for val in mv_set])
                f.write(hex_line + "\n")
                
    print(f"Successfully generated MV.txt with {num_patterns * 64} entries.")

def generate_and_save_arrays(num_patterns):
    
    output_dir = os.path.join(BASE_DIR, str(num_patterns))
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created directory: {output_dir}")
    else:
        print(f"Directory already exists: {output_dir}")

    path_l0 = os.path.join(output_dir, "L0.txt")
    path_l1 = os.path.join(output_dir, "L1.txt")
    # path_l0h = os.path.join(output_dir, "L0h.txt")
    # path_l1h = os.path.join(output_dir, "L1h.txt")

    with open(path_l0, "w") as l0_file, open(path_l1, "w") as l1_file :
        #  open(path_l0h, "w") as l0h_file, open(path_l1h, "w") as l1h_file:
         
        for i in range(num_patterns):
            array_L0 = np.random.randint(0, 256, (128, 128))
            array_L1 = np.random.randint(0, 256, (128, 128))
            
            # --- Correlation Logic ---
            random_offset = np.random.randint(0, 6, size=(8000,))            
            flat_L0 = array_L0.flatten()
            flat_L1 = array_L1.flatten()
            mask = flat_L0[:8000] <= 250 
            flat_L1[:8000][mask] = np.minimum(flat_L0[:8000][mask] + random_offset[mask], 255)
            array_L1 = flat_L1.reshape(128, 128)
            # -------------------------

            np.savetxt(l0_file, array_L0, fmt='%d', delimiter=' ')
            l0_file.write('\n')
            np.savetxt(l1_file, array_L1, fmt='%d', delimiter=' ')
            l1_file.write('\n')
            
            # np.savetxt(l0h_file, array_L0, fmt='%02x', delimiter=' ')
            # l0h_file.write('\n')
            # np.savetxt(l1h_file, array_L1, fmt='%02x', delimiter=' ')
            # l1h_file.write('\n')
            
            if (i+1) % 10 == 0:
                print(f"Added set {i+1} to L0.txt and L1.txt")
            
    # Call MV generator with path
    generate_mv_data(num_patterns, output_dir)

# ==========================================
# 3. Main Execution
# ==========================================
if __name__ == "__main__":
    generate_and_save_arrays(NUM_PATTERNS)