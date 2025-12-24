import random
import os

def generate_input_data(num_patterns, output_file='input/input_data.txt'):
    """
    生成 input_data.txt
    每個pattern生成16384個8-bit數據(十進位),每個數據一行
    """
    with open(output_file, 'w') as f:
        for pattern in range(num_patterns):
            # 標註 pattern 編號
            f.write(f"{pattern}\n\n")
            for i in range(16384):
                data = random.randint(0, 255)  # 8-bit: 0-255
                f.write(f"{data}\n")
    print(f"✓ 已生成 {output_file}")

def generate_input_para_index(num_patterns, output_file='input/input_para_index.txt'):
    """
    生成 input_para_index.txt
    每個pattern生成16個不重複的4-bit index (0-15),每個一行
    """
    with open(output_file, 'w') as f:
        for pattern in range(num_patterns):
            # 標註 pattern 編號
            f.write(f"{pattern}\n\n")
            # 生成0-15的隨機排列,取全部16個
            indices = list(range(16))
            random.shuffle(indices)
            for i in range(16):
                f.write(f"{indices[i]}\n")
    print(f"✓ 已生成 {output_file}")

def generate_input_para_mode(num_patterns, output_file='input/input_para_mode.txt'):
    """
    生成 input_para_mode.txt
    每個pattern生成16組,每組4個隨機的0或1(每行一個bit)
    """
    with open(output_file, 'w') as f:
        for pattern in range(num_patterns):
            # 標註 pattern 編號
            f.write(f"{pattern}\n\n")
            for group in range(16):
                for bit in range(4):
                    mode_bit = random.randint(0, 1)
                    f.write(f"{mode_bit}\n")
    print(f"✓ 已生成 {output_file}")

def generate_input_para_QP(num_patterns, output_file='input/input_para_QP.txt'):
    """
    生成 input_para_QP.txt
    每個pattern生成16個5-bit QP值(0-29),每個一行
    """
    with open(output_file, 'w') as f:
        for pattern in range(num_patterns):
            # 標註 pattern 編號
            f.write(f"{pattern}\n\n")
            for i in range(16):
                qp = random.randint(0, 29)  # QP範圍: 0-29
                f.write(f"{qp}\n")
    print(f"✓ 已生成 {output_file}")

def main():
    # 建立 input 資料夾
    if not os.path.exists('input'):
        os.makedirs('input')
        print("✓ 已建立 input 資料夾\n")
    
    # 設定要生成的pattern數量
    num_patterns = int(input("請輸入要生成的 pattern 數量: "))
    
    # 設定隨機種子(可選,用於可重現的結果)
    seed = 1
    if seed:
        random.seed(int(seed))
    
    print(f"\n開始生成 {num_patterns} 個 patterns 的測試檔案...\n")
    
    # 生成所有檔案
    generate_input_data(num_patterns)
    generate_input_para_index(num_patterns)
    generate_input_para_mode(num_patterns)
    generate_input_para_QP(num_patterns)
    
    print(f"\n✓ 所有檔案生成完成!")
    print(f"\n檔案說明:")
    print(f"  - input/input_data.txt: {num_patterns * 16385} 行 (每個pattern 1行註解 + 16384行數據)")
    print(f"  - input/input_para_index.txt: {num_patterns * 17} 行 (每個pattern 1行註解 + 16行)")
    print(f"  - input/input_para_mode.txt: {num_patterns * 65} 行 (每個pattern 1行註解 + 64行)")
    print(f"  - input/input_para_QP.txt: {num_patterns * 17} 行 (每個pattern 1行註解 + 16行)")

if __name__ == "__main__":
    main()