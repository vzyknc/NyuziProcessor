//
// Copyright 2016 Jeff Bush
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#include "asm_macros.h"

//
// Ensure that writing to a control register while in user mode raises a fault
// and doesn't update the register.
//

                .globl _start
_start:
                // Set up fault handler
                lea s0, handle_fault
                setcr s0, CR_TRAP_HANDLER

                // Clear scratchpad 0. We will attempt to update it, and the
                // fault handler will check that it wasn't.
                move s0, 0
                setcr s0, CR_SCRATCHPAD0

                // Switch to user mode
                setcr s0, CR_FLAGS
                flush_pipeline

                li s0, 0xdeadbeef
fault_loc:      setcr s0, CR_SCRATCHPAD0        // This should fault

                should_not_get_here

handle_fault:   getcr s0, CR_SCRATCHPAD0
                assert_reg s0, 0
                getcr s0, CR_TRAP_CAUSE
                assert_reg s0, TT_PRIVILEGED_OP
                getcr s0, CR_FLAGS
                assert_reg s0, FLAG_SUPERVISOR_EN
                getcr s0, CR_SAVED_FLAGS
                assert_reg s0, 0
                getcr s0, CR_TRAP_PC
                lea s1, fault_loc
                cmpeq_i s0, s0, s1
                bnz s0, 1f
                call fail_test
1:              call pass_test
