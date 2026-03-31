import math
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge

def real_to_fixed(val):
    """Converts a float to a 16-bit signed fixed-point integer (Q2.13)."""
    # 2^13 scale factor
    scaled = int(val * (2**13))
    # Handle two's complement for negative numbers
    if scaled < 0:
        scaled = (1 << 16) + scaled
    return scaled & 0xFFFF

def fixed_to_real(val):
    """Converts a 16-bit signed fixed-point integer (Q2.13) to a float."""
    # If the sign bit is set (bit 15), it's a negative number in two's complement
    if val & 0x8000:
        val = val - (1 << 16)
    return val / (2**13)

@cocotb.test()
async def cordic_test(dut):
    """Test the CORDIC module across a range of angles."""
    
    # 1. Start the clock (10ns period -> 100MHz)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 2. Initialize inputs
    dut.ena.value = 1
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    
    # Wait a few cycles and release reset
    await Timer(100, units="ns")
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await FallingEdge(dut.clk)
    
    # Test parameters
    sin_cos_mode = 1  # 1 for Cosine (matching your Verilog tb logic), 0 for Sine
    
    dut._log.info("Starting SINE/COSINE TEST....")
    
    # Loop from -180 to 180 in steps of 15 degrees
    for theta in range(-180, 181, 15):
        # Calculate ideal rads and map to fixed point
        theta_rad = math.pi * theta / 180.0
        angle_in = real_to_fixed(theta_rad)
        
        # We need to feed the 16-bit value in 4-bit nibbles
        # ui_in mapping based on your Verilog:
        # [7]: valid, [6]: sin_cos, [5:4]: byte_select, [3:0]: angle_data
        
        # Send 4 chunks
        for byte_select in range(4):
            valid = 1
            # Extract the correct 4-bit chunk
            angle_data = (angle_in >> (byte_select * 4)) & 0xF
            
            # Pack the 8-bit ui_in bus
            ui_val = (valid << 7) | (sin_cos_mode << 6) | (byte_select << 4) | angle_data
            dut.ui_in.value = ui_val
            
            # Wait 100ns before sending the next nibble (as per your Verilog TB)
            await Timer(100, units="ns")
            
        # Wait for the computation to finish (your TB used #100000)
        await Timer(100, units="ns") # You might need more/less cycles depending on pipeline depth!
        
        # Read result (Concatenating uio_out and uo_out)
        uio_out_val = dut.uio_out.value.integer
        uo_out_val = dut.uo_out.value.integer
        y_val = (uio_out_val << 8) | uo_out_val
        
        dut_result = fixed_to_real(y_val)
        
        # Calculate expected result
        if sin_cos_mode == 0:
            expected_result = math.sin(theta_rad)
            mode_str = "Sine"
        else:
            expected_result = math.cos(theta_rad)
            mode_str = "Cosine"
            
        err = abs(dut_result - expected_result)
        
        dut._log.info("--------------------------------------------------")
        dut._log.info(f"Mode: {mode_str}, Angle(Degree) = {theta}")
        dut._log.info(f"RESULT -> DUT: {dut_result:.6f}  Expected: {expected_result:.6f}  Error: {err:.4e}")
        
        # Cooldown period between operations
        await Timer(10, units="us")
        
    dut._log.info("Test Completed.")
