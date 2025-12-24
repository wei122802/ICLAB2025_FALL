import random
from pathlib import Path

random.seed(1)

def generate_hex(bits):
    """生成指定位數的隨機十六進位數"""
    max_val = (2 ** bits) - 1
    return format(random.randint(0, max_val), f'0{bits//4}X')

def generate_single_testcase():
    """生成單個測試案例的數據"""
    data = {
        'packets': [generate_hex(16) for _ in range(8)],  
        'key': generate_hex(64),                         
        'channel_loads': [generate_hex(4) for _ in range(3)],     
        'channel_capacities': [generate_hex(3) for _ in range(3)]  
    }
    return data

def parse_packets(data):
    """解析 data['packets']，將每個 16bit packet 拆成各欄位"""
    parsed_packets = []

    for packet_hex in data['packets']:

        packet_val = int(packet_hex, 16)

        req_valid    = (packet_val >> 15) & 0x1         
        qos          = (packet_val >> 13) & 0x3         
        pkt_len      = (packet_val >> 9) & 0xF         
        congestion   = (packet_val >> 7) & 0x3             
        prefer_ch    = (packet_val >> 5) & 0x3            
        src_hint     = (packet_val >> 2) & 0x7               
        mode         = (packet_val >> 1) & 0x1              


        parsed_packets.append({
            'req_valid': req_valid,
            'qos': qos,
            'pkt_len': pkt_len,
            'congestion': congestion,
            'prefer_ch': prefer_ch,
            'src_hint': src_hint,
            'mode': mode
        })
    print(parsed_packets)
    return parsed_packets

def generate_batch_testcases(pattern_count):
    """生成批量測試案例並輸出到input.txt 與 parsed.txt"""
    
    Path("output").mkdir(exist_ok=True)
    
    with open('output/input.txt', 'w') as f_in, open('output/parsed.txt', 'w') as f_parsed:

        f_in.write(f"{pattern_count}\n")
        f_parsed.write(f"{pattern_count}\n")

        for i in range(pattern_count):
            print(f"正在生成第 {i+1}/{pattern_count} 個測試案例...")
            data = generate_single_testcase()
            
            for packet in data['packets']:
                f_in.write(f"{packet}\n")
            print(data['packets'])
            f_in.write(f"{data['key']}\n")
            for load in data['channel_loads']:
                f_in.write(f"{load}\n")
            for capacity in data['channel_capacities']:
                f_in.write(f"{capacity}\n")
            f_in.write("\n")

            parsed = parse_packets(data)
            f_parsed.write(f"Testcase {i+1}:\n")
            for j, pkt in enumerate(parsed):
                f_parsed.write(f"  Packet{j}: {pkt}\n")
            f_parsed.write("\n")
    
    print(f"成功生成 {pattern_count} 個測試案例，儲存在 ./output/input.txt 與 ./output/parsed.txt")


if __name__ == "__main__":
    pattern_count = int(input("請輸入要生成的測試案例數量: "))
    generate_batch_testcases(pattern_count)
