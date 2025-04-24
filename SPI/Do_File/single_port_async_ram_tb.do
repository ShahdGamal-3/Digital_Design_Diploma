vlib work
vlog single_port_async_ram.v single_port_async_ram_tb.v
vsim -voptargs=+acc work.single_port_async_ram_tb
add wave *
run -all

