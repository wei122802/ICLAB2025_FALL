###################################################################

# Created by write_sdc on Tue Jul 25 03:44:35 2023

###################################################################
set sdc_version 2.1

#=============================================================================================
# The basic condition for clock tree synthesis and its timing analysis
# You cannot modify the setting below, or you must get failure in this lab
#=============================================================================================
set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
set_operating_conditions -max WCCOM -max_library                               \
fsa0m_a_generic_core_ss1p62v125c\
                         -min BCCOM -min_library                               \
fsa0m_a_generic_core_ff1p98vm40c
set_drive 0.1 [all_inputs]
set_load -pin_load 20 [all_outputs]

#=============================================================================================
# You should modify your desired cycle time for post-layout simulation (06_POST)
# input / output delay should be half of cycle time, or you might get failure in this lab
#=============================================================================================
create_clock [get_ports clk]  -period 11.6  -waveform {0 5.8}
set_input_delay     5.8 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay    5.8 -clock clk [all_outputs]



