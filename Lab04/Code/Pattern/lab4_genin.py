import numpy as np
import random
import struct
from pathlib import Path

# ======== Helper Functions ========
# np.random.seed(1)   # 固定 numpy 亂數
# random.seed(1)      # 固定 Python random 亂數

np.random.seed(10)   # 固定 numpy 亂數
random.seed(10)      # 固定 Python random 亂數

def float_to_hex(f):
    return format(struct.unpack('<I', struct.pack('<f', f))[0], '08X')

def pad_image(img, mode):
    """mode[1] 決定 padding 方式"""
    if (mode >> 1) & 1 == 0:   # 0 = Replication
        return np.pad(img, pad_width=1, mode='edge')
    else:                      # 1 = Reflection
        return np.pad(img, pad_width=1, mode='reflect')

def convolution(image, kernel):
    out = np.zeros((6, 6))
    k = kernel.reshape((3, 3))
    for m in range(6):
        for n in range(6):
            region = image[m:m+3, n:n+3]
            out[m, n] = np.sum(region * k)
    return np.round(out, 7)

def max_pooling(image):
    assert image.shape == (6, 6), "Input image must be 6x6"
    out = np.zeros((2, 2))

    out[0, 0] = np.max(image[0:3, 0:3])
    out[0, 1] = np.max(image[0:3, 3:6])
    out[1, 0] = np.max(image[3:6, 0:3])
    out[1, 1] = np.max(image[3:6, 3:6])

    return np.round(out, 7)

def leaky_relu(x):
    """Leaky ReLU"""
    return np.where(x >= 0, x, 0.01 * x)

def swish(x):
    return x / (1.0 + np.exp(-x))

def apply_activation(matrix, mode):
    if mode in [1, 3]:  # swish
        return np.round(swish(matrix), 7)
    elif mode in [0, 2]:  # tanh
        return np.round(np.tanh(matrix), 7)
    else:
        raise ValueError(f"Invalid mode: {mode}")
    
def generate_single_testcase():
    """生成單個測試案例並返回所有hex數據"""
    task = random.randint(0, 1)
    print(task)
    # ======== 1. Generate image.txt (2 張 6x6) ========
    if (task==0):
        image_vals = np.round(np.random.uniform(-0.5, 0.5, 72), 7)
        image1 = image_vals[0:36].reshape((6, 6))
        image2 = image_vals[36:72].reshape((6, 6))
    else :
        image_vals = np.round(np.random.uniform(-0.5, 0.5, 36), 7)
        image1 = image_vals[0:36].reshape((6, 6))
        image2 =0
    # print("image1" , image1)
    # print("image2" , image2)
    # ======== 2. Generate Kernels (2 個 3x3) ========
    K1 = np.round(np.random.uniform(-0.5, 0.5, 18), 7)  # kernel1 有 2*9
    K2 = np.round(np.random.uniform(-0.5, 0.5, 18), 7)  # kernel2 有 2*9

    Kernel_1_1 = K1[0:9].reshape(3, 3)
    Kernel_1_2 = K1[9:18].reshape(3, 3)

    Kernel_2_1 = K2[0:9].reshape(3, 3)
    Kernel_2_2 = K2[9:18].reshape(3, 3)
    # print("Kernel_1_1" , Kernel_1_1)
    # print("Kernel_1_2" , Kernel_1_2)
    # print("Kernel_2_1" , Kernel_2_1)
    # print("Kernel_2_2" , Kernel_2_2)
    # weights = np.round(np.random.uniform(-0.5, 0.5, 57), 7)
    # ======== 3. Generate Weight.txt (8 個 * 3 組 = 24) ========
    if(task==0):
        weights = np.round(np.random.uniform(-0.5, 0.5, 57), 7)
        Weight1 = weights[0:40]
        Weight2 = weights[41:56]
        bias1 = weights[40]
        bias2 = weights[56]
        # print("weights" , weights)
        # print("Weight1" , Weight1)
        # print("Weight2" , Weight2)
        # print("bias1" , bias1)
        # print("bias2" , bias2)

        # ======== 4. Generate mode.txt (2 bits) ========
        mode = random.randint(0, 3)
        print("mode=",mode)
        # ======== 5. Padding ========
        padding_ch1 = pad_image(image1, mode)
        padding_ch2 = pad_image(image2, mode)
        # print("padding_ch1" , padding_ch1)
        # print("padding_ch2" , padding_ch2)
        # ======== 6. Convolution ========
        partial_1_1 = convolution(padding_ch1, Kernel_1_1)
        partial_1_2 = convolution(padding_ch2, Kernel_1_2)
        out_ch1 = partial_1_1 + partial_1_2
        # print("out_ch1" , out_ch1)
        # print("partial_1_1",partial_1_1)
        # print("partial_1_2",partial_1_2)

        partial_2_1 = convolution(padding_ch1, Kernel_2_1)
        partial_2_2 = convolution(padding_ch2, Kernel_2_2)
        # print("partial_2_1",partial_2_1)
        # print("partial_2_2",partial_2_2)
        out_ch2 = partial_2_1 + partial_2_2
        # print("out_ch2" , out_ch2)
        # print("out_ch1" , out_ch1)
        # print("out_ch2" , out_ch2)
        
        # ======== 7. Pooling ========
        max_pooling_ch1 = max_pooling(out_ch1)
        max_pooling_ch2 = max_pooling(out_ch2)
        # print("max_pooling_ch1" , max_pooling_ch1)
        # print("max_pooling_ch2[0][0]" , max_pooling_ch2[0][0])
        # print("max_pooling_ch2" , max_pooling_ch2)
        
        # ======== 8. activation ========
        act_1 = apply_activation(max_pooling_ch1, mode)
        act_2 = apply_activation(max_pooling_ch2, mode)
        # print("act_1 = \n", act_1)
        # print("act_2 = \n", act_2)
        
        # ======== 9. Fully Connection ========

        act_vector = np.concatenate((act_1.flatten(), act_2.flatten()))
        # print(Weight1[0:8])
        FC1 = np.round(np.dot(act_vector, Weight1[0:8] ) + bias1 , 7)
        FC2 = np.round(np.dot(act_vector, Weight1[8:16] ) + bias1 , 7)
        FC3 = np.round(np.dot(act_vector, Weight1[16:24] ) + bias1 , 7)
        FC4 = np.round(np.dot(act_vector, Weight1[24:32] ) + bias1 , 7)
        FC5 = np.round(np.dot(act_vector, Weight1[32:40] ) + bias1 , 7)
        # FC_output = np.round(np.dot(act_vector, Weight1) + bias1, 7)
        # print("FC1 = \n", FC1)
        # print("FC2 = \n", FC2)
        # print("FC3 = \n", FC3)
        # print("FC4 = \n", FC4)
        # print("FC5 = \n", FC5)
        
        # ======== 10. Leaky ========
        FC1_leaky = np.round(leaky_relu(FC1), 7)
        FC2_leaky = np.round(leaky_relu(FC2), 7)
        FC3_leaky = np.round(leaky_relu(FC3), 7)
        FC4_leaky = np.round(leaky_relu(FC4), 7)
        FC5_leaky = np.round(leaky_relu(FC5), 7)
        # print("FC1_leaky = \n", FC1_leaky)
        # print("FC2_leaky = \n", FC2_leaky)
        # print("FC3_leaky = \n", FC3_leaky)    
        # print("FC4_leaky = \n", FC4_leaky)
        # print("FC5_leaky = \n", FC5_leaky)
        # ======== 11. Fully Connection 2 ========
        FC_leaky = np.array([FC1_leaky, FC2_leaky, FC3_leaky, FC4_leaky, FC5_leaky])
        # print ("FC_leaky" , FC_leaky)
        FC_Layer2_1 = np.round(np.dot(FC_leaky, Weight2[0:5] ) + bias2 , 7)
        FC_Layer2_2 = np.round(np.dot(FC_leaky, Weight2[5:10] ) + bias2 , 7)
        FC_Layer2_3 = np.round(np.dot(FC_leaky, Weight2[10:15] ) + bias2 , 7)
        FC_Layer2 = np.array([FC_Layer2_1, FC_Layer2_2, FC_Layer2_3 ])
        # print("FC_Layer2 = \n", FC_Layer2)
        # ======== 12. Softmax ========
        FC1_exp = np.exp(FC_Layer2_1)
        FC2_exp = np.exp(FC_Layer2_2)
        FC3_exp = np.exp(FC_Layer2_3)
        # print("FC1_exp = \n", FC1_exp)
        # print("FC2_exp = \n", FC2_exp)
        # print("FC3_exp = \n", FC3_exp)
        
        FC_sum_temp = FC1_exp+FC2_exp+FC3_exp
        # print("FC_sum_temp = \n", FC_sum_temp)
        out1 = FC1_exp / FC_sum_temp
        out2 = FC2_exp / FC_sum_temp
        out3 = FC3_exp / FC_sum_temp
        output = np.array([out1, out2, out3])
        print(output)
        
        # ======== 13. Capacity_cost (5 個 4bit) ========
        capacity_cost = [random.randint(0, 15) for _ in range(5)]   
    else :
        weights = np.round(np.random.uniform(0.0, 0.0, 1), 7)
        while True:
            capacity = random.randint(5, 15)
            costs = [random.randint(1, 15) for _ in range(4)]
            if capacity >= min(costs):  # 確保 capacity 至少不比所有 cost 小
                break
        capacity_cost = [capacity] + costs
        # print("capacity_cost =", capacity_cost)
        
        mode = random.randint(0, 3)
        # print("mode =", mode)
        padding_ch1 = pad_image(image1, mode)

        partial_1_1 = convolution(padding_ch1, Kernel_1_1)
        partial_1_2 = convolution(padding_ch1, Kernel_1_2)
        partial_2_1 = convolution(padding_ch1, Kernel_2_1)
        partial_2_2 = convolution(padding_ch1, Kernel_2_2)
        ResultA = np.sum(partial_1_1)
        ResultB = np.sum(partial_1_2)
        ResultC = np.sum(partial_2_1)
        ResultD = np.sum(partial_2_2)
        results = [ResultA, ResultB, ResultC, ResultD]
        # print(f"Results: {results}")

        cost_A, cost_B, cost_C, cost_D = costs
        best_sum = -float('inf')
        best_combo = [0, 0, 0, 0]

        for combo in range(16):
            sel_A = (combo >> 3) & 1
            sel_B = (combo >> 2) & 1
            sel_C = (combo >> 1) & 1
            sel_D = combo & 1

            total_cost = sel_A * cost_A + sel_B * cost_B + sel_C * cost_C + sel_D * cost_D
            current_sum = 0
            valid = True
            has_positive = False

            for i, sel in enumerate([sel_A, sel_B, sel_C, sel_D]):
                if sel:
                    if results[i] > 0:
                        current_sum += results[i]
                        has_positive = True
                    else:
                        valid = False

            if valid and total_cost <= capacity and has_positive and current_sum > 0:
                if current_sum > best_sum:
                    best_sum = current_sum
                    best_combo = [sel_A, sel_B, sel_C, sel_D]

        # print(f"Best Combo = {best_combo}, Best Sum = {best_sum}")
        out_binary = ''.join(str(x) for x in [0]*28 + best_combo)
        out_val = int(out_binary, 2)
        output = f"{out_val:08X}"
        
    # 轉換為hex格式
    def values_to_hex_list(values):
        return [float_to_hex(val) for val in values.flatten() if not np.isnan(val)]
    if(task==0):
        hex_data = {
            'image': values_to_hex_list(image_vals),
            'kernel_ch1': values_to_hex_list(K1),
            'kernel_ch2': values_to_hex_list(K2),
            'weight': values_to_hex_list(weights),
            'mode': str(mode),
            'task': str(task),
            'capacity_cost': [str(c) for c in capacity_cost],
            'out': values_to_hex_list(np.array(output))
        }
    else :
        hex_data = {
            'image': values_to_hex_list(image_vals),
            'kernel_ch1': values_to_hex_list(K1),
            'kernel_ch2': values_to_hex_list(K2),
            'weight': values_to_hex_list(weights),
            'mode': str(mode),
            'task': str(task),
            'capacity_cost': [str(c) for c in capacity_cost],
            'out': [output]
        }

    return hex_data

def generate_batch_testcases(y):
    """生成y個測試案例並輸出到指定格式的檔案"""
    Path("output").mkdir(exist_ok=True)

    files = {
        'image': 'output/image.txt',
        'kernel_ch1': 'output/kernel_ch1.txt',
        'kernel_ch2': 'output/kernel_ch2.txt',
        'weight': 'output/weight.txt',
        'mode': 'output/mode.txt',
        'task': 'output/task.txt',
        'capacity_cost': 'output/capacity_cost.txt',
        'out': 'output/out.txt'
    }

    for filename in files.values():
        open(filename, 'w').close()

    for i in range(y):
        print(f"正在生成第 {i+1}/{y} 個測試案例...")
        hex_data = generate_single_testcase()

        for data_type, filename in files.items():
            with open(filename, 'a') as f:
                f.write(f"{i}\n")
                if data_type in ['mode', 'task']:
                    f.write(f"{hex_data[data_type]}\n\n")
                elif data_type == 'capacity_cost':
                    for line in hex_data[data_type]:
                        f.write(f"{line}\n")
                    f.write("\n")
                else:
                    for hex_val in hex_data[data_type]:
                        f.write(f"{hex_val}\n")
                    f.write("\n")

    print(f"已成功生成 {y} 個測試案例，儲存在 ./output 資料夾。")

if __name__ == "__main__":
    y = int(input("請輸入要生成的測試案例數量 (y): "))
    generate_batch_testcases(y)
