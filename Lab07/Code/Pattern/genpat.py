import random

# --- 根據 PDF P.2 & P.5 定義的常數 ---
N = 128         # 轉換大小 (degree)
Q = 12289       # 模數 (Modulus)
QOI = 12287     # Q 的 Montgomery inverse
R = 2**16       # Montgomery R
NUM_PATTERNS = 100 # 總共要產生的測試樣本數

# --- 輔助函式：模數運算 ---

def mod_add(a, b, q):
    """ (a + b) mod Q """
    res = a + b
    return res - q if res >= q else res

def mod_sub(a, b, q):
    """ (a - b) mod Q [cite: 68, 94-99] """
    res = a - b
    return res + q if res < 0 else res

def modq_mul(a, b, q, qoi, r):
    """ Montgomery 乘法 (modq_mul) [cite: 71-87] """
    x = a * b
    y = (x * qoi) % r  # y = (x * QOI) mod R
    z = (x + y * q) // r # z = (x + y * Q) / R
    
    if z >= q:         # if (z >= Q) return z - Q
        return z - q
    else:              # else return z
        return z

# --- 核心 NTT 演算法 ---

def ntt(x_in, gmb, n, q, qoi, r):
    """ 實作 PDF P.2 的 NTT 演算法 [cite: 46-70] """
    x = list(x_in) # 複製一份輸入，避免修改到原始資料
    t = n # t = 128
    
    m = 1
    while m < n: # for (m=1; m<128; m=m*2)
        ht = t // 2 # ht = t/2
        j1 = 0
        for i in range(m): # for (i=0; i<m; i=i+1)
            s = gmb[m + i] # s = GMb[m+i]
            j2 = j1 + ht # j2 = j1 + ht
            for j in range(j1, j2): # for (j=j1; j<j2; j=j+1)
                u = x[j] # u = x[j]
                v = modq_mul(x[j + ht], s, q, qoi, r) # v = modq_mul(x[j+ht], s)
                
                x[j] = mod_add(u, v, q)     # x[j] = (u+v) mod Q
                x[j + ht] = mod_sub(u, v, q) # x[j+ht] = (u-v) mod Q
            
            j1 = j1 + t
        t = ht # t = ht
        m = m * 2
        
    return x

# --- 檔案產生主程式 ---

def generate_files():
    print(f"正在產生 {NUM_PATTERNS} 組測試樣本...")

    # ==========================================================
    # vvvvvvvvvvvv 這裡是修改過的地方 vvvvvvvvvvvv
    # ==========================================================
    
    # 1. 讀取 GMb.txt (Twiddle Factors)
    gmb_factors = []
    try:
        with open("GMb.txt", "r") as f:
            for line in f:
                line = line.strip()
                if line: # 確保不是空行
                    # *** 將 line 視為 10 進位 (Decimal) 進行轉換 ***
                    val = int(line) 
                    gmb_factors.append(val)
        
        # 檢查是否讀取了足夠的 N (128)
        if len(gmb_factors) < N:
            print(f"錯誤：GMb.txt 只包含 {len(gmb_factors)} 個值，但演算法需要 {N} 個。")
            return
        
        # 如果 GMb.txt 檔案大於 N, 只取前 N 個
        if len(gmb_factors) > N:
             print(f"警告：GMb.txt 包含 {len(gmb_factors)} 個值，但只會使用前 {N} 個。")
             gmb_factors = gmb_factors[:N]
             
        print("已成功讀取 (十進制) GMb.txt")

    except FileNotFoundError:
        print("錯誤：找不到 GMb.txt 檔案。請確保檔案存在於同一個目錄。")
        return
    except ValueError as e:
        print(f"錯誤：讀取 GMb.txt 時發生錯誤。請確保檔案內容為 10 進位格式: {e}")
        return
    except IOError as e:
        print(f"錯誤：無法讀取 GMb.txt: {e}")
        return
        
    # ==========================================================
    # ^^^^^^^^^^^^ 這裡是修改過的地方 ^^^^^^^^^^^^
    # ==========================================================

    try:
        # 2. 開啟 input.txt 和 output.txt 準備寫入
        with open("input.txt", "w") as f_in, open("output.txt", "w") as f_out:
            for pat_num in range(NUM_PATTERNS):
                
                # 3. 產生 128 個 4-bit 輸入係數
                in_coeffs = [random.randint(0, 15) for _ in range(N)]
                
                # 4. 呼叫 NTT 函式計算黃金答案 (使用讀入的 gmb_factors)
                out_coeffs = ntt(in_coeffs, gmb_factors, N, Q, QOI, R)
                
                # 5. 寫入 input.txt
                # 每個 in_data (32-bit) 包含 8 個 4-bit 係數
                # 共 16 個 cycle (16 * 8 = 128 個係數)
                for i in range(16): # 16 cycles
                    in_data_32bit = 0
                    base_idx = i * 8
                    # [cite_start]根據 Fig. 8，x0 在 LSB [cite: 253, 270]
                    for j in range(8):
                        in_data_32bit |= (in_coeffs[base_idx + j] & 0xF) << (j * 4)
                    
                    f_in.write(f"{in_data_32bit:08x}\n") # 寫入 32-bit 16進位值
                
                # 6. 寫入 output.txt
                # 128 個 16-bit 輸出
                for val in out_coeffs:
                    f_out.write(f"{val:04x}\n") # 寫入 16-bit 16進位值

        print(f"已成功產生 input.txt 和 output.txt ({NUM_PATTERNS} 組樣本)")

    except IOError as e:
        print(f"錯誤：無法寫入 input/output 檔案: {e}")

# --- 執行 ---
if __name__ == "__main__":
    generate_files()