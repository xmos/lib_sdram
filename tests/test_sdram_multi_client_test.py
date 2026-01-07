# Copyright 2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import pytest
import Pyxsim
from Pyxsim import testers
from pathlib import Path

def test_sdram_multi_client_test(level, capfd):

    if level == 'smoke':
        pytest.skip("level == 'smoke'")

    binary = Path(__file__).parent / "sdram_multi_client_test" / "bin" / "sdram_multi_client_test.xe"

    tester = None

    max_cycles = 15000

    simargs = [
        "--max-cycles",
        str(max_cycles),
    ]

    result = Pyxsim.run_on_simulator(
        binary,
        cmake=True,
        simargs=simargs,
        tester=tester,
        capfd=capfd,
        clean_before_build=False)