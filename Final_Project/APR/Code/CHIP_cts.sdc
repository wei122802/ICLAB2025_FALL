###################################################################

# Created by write_sdc on Thu Mar 13 15:04:04 2025

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
set_operating_conditions -max WCCOM -max_library                               \
fsa0m_a_generic_core_ss1p62v125c\
                         -min BCCOM -min_library                               \
fsa0m_a_generic_core_ff1p98vm40c

create_clock [get_ports clk]  -period 11.1  -waveform {0 5.55}
set_drive 0.1 [all_inputs]
set_load -pin_load 20 [all_outputs]
set_input_delay 5.55 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 5.55 -clock clk [all_outputs]