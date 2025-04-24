vlib work
vlog single_port_async_ram.v spi_slave_interface.v spi_slave_interface_tb.v
vsim -voptargs=+acc work.spi_slave_interface_tb
add wave *
run -all

